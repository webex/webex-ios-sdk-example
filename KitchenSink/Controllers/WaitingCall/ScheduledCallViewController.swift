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
    public var tableView = UITableView()
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.incomingCallListChanged(notification:)), name: Notification.Name("IncomingCallListChanged"), object: nil)
    }
    
    @objc func incomingCallListChanged(notification: Notification) {
        if let info = notification.userInfo {
            info["ring"] as? Bool ?? false ? startRinging() : stopRinging()
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRinging()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Custom cell for one to one call
        if incomingCallData[indexPath.row].isScheduledCall == false {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: IncomingCallViewCell.reuseIdentifier, for: indexPath) as? IncomingCallViewCell else { return UITableViewCell() }
            
            cell.setupCallCell(name: incomingCallData[indexPath.row].organizer, connectButtonActionHandler: { [weak self] in self?.connectCallTapped(indexPath: indexPath) }, endButtonActionHandler: { [weak self] in self?.endCallTapped(indexPath: indexPath) })
        return cell
        } else {
        // Custom cell for Scheduled Meeting
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ScheduledMeetingTableViewCell.reuseIdentifier, for: indexPath) as? ScheduledMeetingTableViewCell else { return UITableViewCell() }
            cell.setupCell(name: incomingCallData[indexPath.row].subject, start: incomingCallData[indexPath.row].start, end: incomingCallData[indexPath.row].end, joinButtonActionHandler: { [weak self] in self?.joinButtonTapped(indexPath: indexPath)
        })
            return cell
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return incomingCallData.count
    }

    private func joinButtonTapped(indexPath: IndexPath) {
        guard let space = incomingCallData[indexPath.row].space, let currentCallId = incomingCallData[indexPath.row].currentCallId else {
            let alert = UIAlertController(title: "Alert", message: "Join Failed", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return }
        if let callId = incomingCallData[indexPath.row].currentCallId, let call = CallObjectStorage.self.shared.getCallObject(callId: callId) {
            let callVC = CallViewController(space: space, addedCall: false, currentCallId: currentCallId, incomingCall: true, call: call)
            self.present(callVC, animated: true)
        }
    }

    private func connectCallTapped(indexPath: IndexPath) {
        self.player?.stop()
        guard let space = incomingCallData[indexPath.row].space, let currentCallId = incomingCallData[indexPath.row].currentCallId else {
            let alert = UIAlertController(title: "Alert", message: "Connect Call Failed", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return }
        DispatchQueue.main.async {
            incomingCallData.remove(at: indexPath.row)
            self.tableView.reloadData()
        }
        if let callId = incomingCallData[indexPath.row].currentCallId, let call = CallObjectStorage.self.shared.getCallObject(callId: callId) {
            let callVC = CallViewController(space: space, addedCall: false, currentCallId: currentCallId, incomingCall: true, call: call)
            self.present(callVC, animated: true)
        }
    }

    private func endCallTapped(indexPath: IndexPath) {
        guard let callId = incomingCallData[indexPath.row].currentCallId, let call = CallObjectStorage.self.shared.getCallObject(callId: callId) else {
            return
        }
        
        call.reject(completionHandler: { error in
            if error == nil {
                self.player?.stop()
                DispatchQueue.main.async {
                    incomingCallData.remove(at: indexPath.row)
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
        let currentCell = "Organizer : \(incomingCallData[indexPath.row].organizer), Start : \(String(describing: incomingCallData[indexPath.row].start)), End : \(String(describing: incomingCallData[indexPath.row].end)), Link : \(incomingCallData[indexPath.row].link), Meeting Id : \(incomingCallData[indexPath.row].meetingId), Subject : \(incomingCallData[indexPath.row].subject)"
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
