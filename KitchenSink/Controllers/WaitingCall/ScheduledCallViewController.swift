import AVKit
import UIKit
import WebexSDK
// Struct to store the various attributes of each call/meeting
struct Meeting {
    var organizer: String
    var start: Date?
    var end: Date?
    var meetingId: String
    var link: String
    var subject: String
    var isScheduledCall: Bool
    var currentCallId: String?
    var space: Space?
    
    init(organizer: String, start: Date?, end: Date?, meetingId: String, link: String, subject: String, isScheduledCall: Bool, space: Space, currentCallId: String) {
        self.organizer = organizer
        self.start = start
        self.end = end
        self.meetingId = meetingId
        self.link = link
        self.subject = subject
        self.isScheduledCall = isScheduledCall
        self.currentCallId = currentCallId
        self.space = space
    }
}

class ScheduledMeetingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var player: AVAudioPlayer?
    var currentCallId: String?
    var space: Space?
    var call: Call?
    
    public var tableView = UITableView()
    public var tableData: [Meeting] = []
    
    func setIncomingCallListener() {
        webex.phone.onIncoming = { call in
            self.call = call
            CallObjectStorage.self.shared.addCallObject(call: call)
            call.onScheduleChanged = { _ in
                DispatchQueue.main.async {
                    self.getUpdatedSchedule(call: call)
                    self.tableView.reloadData()
                }
            }
            DispatchQueue.main.async {
                self.getUpdatedSchedule(call: call)
                self.webexCallStatesProcess(call: call)
                self.tableView.reloadData()
            }
        }
    }

    func getUpdatedSchedule(call: Call) {
        guard let callSchedule = call.schedules else {
            // Case : One to one call ( Only utilizes the title, Space, callId and isScheduledCall)
            currentCallId = call.callId
            space = Space(id: call.spaceId ?? "", title: call.title ?? "")
            let newCall = Meeting(organizer: call.title ?? "", start: Date(), end: Date(), meetingId: "", link: "", subject: "", isScheduledCall: false, space: Space(id: call.spaceId ?? "", title: call.title ?? ""), currentCallId: currentCallId ?? "")
            // Flag to check if meeting is already scheduled (To enter change in the schedule)
            var isExistingScheduleModified = false
            for (rowNumber, var _) in self.tableData.enumerated() where newCall.currentCallId == tableData[rowNumber].currentCallId {
                // Use meeting Id to check if it already exists
                tableData.remove(at: rowNumber)
                tableData.append(newCall)
                isExistingScheduleModified = true
                break
            }
            if !isExistingScheduleModified {
                // Append new Scheduled Meeting
                tableData.append(newCall)
            }
            self.startRinging()
            return
        }

        // Case 2 : Scheduled Meeting
        for item in callSchedule {
            let newMeetingId = Meeting(organizer: item.organzier ?? "", start: item.start, end: item.end, meetingId: item.meetingId ?? "", link: item.link ?? "", subject: item.subject ?? "", isScheduledCall: true, space: Space(id: call.spaceId ?? "", title: call.title ?? ""), currentCallId: call.callId ?? "")
            // Flag to check if meeting is already scheduled (To enter change in the schedule)
            var isExistingScheduleModified = false
            for (rowNumber, var _) in self.tableData.enumerated() where newMeetingId.meetingId == tableData[rowNumber].meetingId {
                // Use meeting Id to check if it already exists
                tableData.remove(at: rowNumber)
                tableData.append(newMeetingId)
                isExistingScheduleModified = true
                break
            }
            if !isExistingScheduleModified {
                // Append new Scheduled Meeting
                self.tableData.append(Meeting(organizer: item.organzier ?? "", start: item.start, end: item.end, meetingId: item.meetingId ?? "", link: item.link ?? "", subject: item.subject ?? "", isScheduledCall: true, space: Space(id: call.spaceId ?? "", title: call.title ?? ""), currentCallId: call.callId ?? ""))
                break
            }
        }
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        self.player?.stop()
        if parent == nil {
            debugPrint("Back Button pressed.")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: self.view.bounds, style: UITableView.Style.plain)
        configureTable()
        setIncomingCallListener()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRinging()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Custom cell for one to one call
        if tableData[indexPath.row].isScheduledCall == false {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: IncomingCallViewCell.reuseIdentifier, for: indexPath) as? IncomingCallViewCell else { return UITableViewCell() }
            cell.setupCallCell(name: tableData[indexPath.row].organizer, connectButtonActionHandler: { [weak self] in self?.connectCallTapped(indexPath: indexPath) }, endButtonActionHandler: { [weak self] in self?.endCallTapped(indexPath: indexPath) })
        return cell
        } else {
        // Custom cell for Scheduled Meeting
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ScheduledMeetingTableViewCell.reuseIdentifier, for: indexPath) as? ScheduledMeetingTableViewCell else { return UITableViewCell() }
            cell.setupCell(name: tableData[indexPath.row].subject, start: tableData[indexPath.row].start, end: tableData[indexPath.row].end, joinButtonActionHandler: { [weak self] in self?.joinButtonTapped(indexPath: indexPath)
        })
            return cell
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    private func joinButtonTapped(indexPath: IndexPath) {
        guard let space = tableData[indexPath.row].space, let currentCallId = tableData[indexPath.row].currentCallId else {
            let alert = UIAlertController(title: "Alert", message: "Join Failed", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return }
        let callVC = CallViewController(space: space, addedCall: false, currentCallId: currentCallId, incomingCall: true, call: call)
        self.present(callVC, animated: true)
    }

    private func connectCallTapped(indexPath: IndexPath) {
        self.player?.stop()
        guard let space = space, let currentCallId = currentCallId else {
            let alert = UIAlertController(title: "Alert", message: "Connect Call Failed", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return }
        DispatchQueue.main.async {
            self.tableData.remove(at: indexPath.row)
            self.tableView.reloadData()
        }
        let callVC = CallViewController(space: space, addedCall: false, currentCallId: currentCallId, incomingCall: true, call: call)
        self.present(callVC, animated: true)
    }

    private func endCallTapped(indexPath: IndexPath) {
        call?.reject(completionHandler: { error in
            if error == nil {
                self.player?.stop()
                DispatchQueue.main.async {
                    self.tableData.remove(at: indexPath.row)
                    self.tableView.reloadData()
                }
            } else {
                let alert = UIAlertController(title: "Error", message: error.debugDescription, preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Ok"))
                self.present(alert, animated: true)
                return
            }
        })
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let currentCell = "Organizer : \(tableData[indexPath.row].organizer), Start : \(String(describing: tableData[indexPath.row].start)), End : \(String(describing: tableData[indexPath.row].end)), Link : \(tableData[indexPath.row].link), Meeting Id : \(tableData[indexPath.row].meetingId), Subject : \(tableData[indexPath.row].subject)"
        showDialog(text: currentCell)
    }

    func showDialog(text: String) {
        let alert = UIAlertController(title: "Meeting Info", message: text, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func startRinging() {
        guard let path = Bundle.main.path(forResource: "call_1_1_ringtone", ofType: "wav") else {
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            self.player = try AVAudioPlayer(contentsOf: url)
            self.player?.numberOfLoops = -1
            self.player?.prepareToPlay()
            self.player?.play()
        } catch {
            print("There is an issue with ringtone")
        }
    }
    
    func stopRinging() {
       self.player?.stop()
    }
    
    func webexCallStatesProcess(call: Call) {
        call.onFailed = { reason in
            print(reason)
            self.stopRinging()
            self.tableData = self.tableData.filter { $0.currentCallId != call.callId }
            self.tableView.reloadData()
        }
        
        call.onDisconnected = { reason in
            switch reason {
            case .callEnded:
                CallObjectStorage.self.shared.removeCallObject(callId: call.callId ?? "")
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            case .localLeft:
                print(reason)
                
            case .localDecline:
                print(reason)
                
            case .localCancel:
                print(reason)
                
            case .remoteLeft:
                print(reason)
                
            case .remoteDecline:
                print(reason)
                
            case .remoteCancel:
                print(reason)
                
            case .otherConnected:
                print(reason)
                
            case .otherDeclined:
                print(reason)
                
            case .error(let error):
                print(error)
            @unknown default:
                print(reason)
            }
            
            self.stopRinging()
            self.tableData = self.tableData.filter { $0.currentCallId != call.callId }
            self.tableView.reloadData()
        }
    }
}

extension ScheduledMeetingViewController {
    private func configureTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.white
        tableView.register(ScheduledMeetingTableViewCell.self, forCellReuseIdentifier: ScheduledMeetingTableViewCell.reuseIdentifier)
        tableView.register(IncomingCallViewCell.self, forCellReuseIdentifier: IncomingCallViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
    }
}
