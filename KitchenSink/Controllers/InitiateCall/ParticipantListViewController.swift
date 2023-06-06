import UIKit
import WebexSDK

class ParticipantListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: Properties
    private let kCellId = "ParticipantCell"
    private var callParticipants: [CallMembership] = []
    private let call: Call
    private var mutedAll: Bool = false
    
    private let titles = ["In Meeting", "In Lobby", "Not in Meeting"]
    private var inMeeting: [CallMembership] = []
    private var notInMeeting: [CallMembership] = []
    private var inLobby: [CallMembership] = []
    
    init(participants: [CallMembership], call: Call) {
        self.callParticipants = participants
        self.call = call
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle Methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.callParticipants = self.call.memberships
        updateMeetingParticipant()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setRightBarButton(muteAllButton, animated: true)
        view.backgroundColor = .backgroundColor
        setupViews()
        setupConstraints()
        participantsStatesProcess()
        if call.isGroupCall && !call.isCUCMCall {
            self.navigationItem.setRightBarButton(muteAllButton, animated: true)
        }
    }
    
    // MARK: TableView Datasource
    func numberOfSections(in tableView: UITableView) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titles[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return inMeeting.count
        case 1:
            return inLobby.count
        case 2:
            return notInMeeting.count
        default:
            return notInMeeting.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: kCellId, for: indexPath) as? ParticipantTableViewCell else {
            return UITableViewCell()
        }
        var participant: CallMembership

        switch indexPath.section {
        case 0:
            participant = inMeeting[indexPath.row]
        case 1:
            participant = inLobby[indexPath.row]
        case 2:
            participant = notInMeeting[indexPath.row]
        default:
            participant = inMeeting[indexPath.row]
        }
        cell.setupCell(name: "\(participant.displayName ?? "ParticipantX"): \(participant.deviceType ?? .unknown)" , isAudioMuted: !participant.sendingAudio)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if call.isCUCMCall {
                let alert = UIAlertController(title: "Not Supported", message: "CUCM call doesn't support this feature", preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Ok"))
                self.present(alert, animated: true)
            } else {
                if (inMeeting[indexPath.row].pairedMemberships.count > 0)
                {
                    var paired = ""
                    for i in inMeeting[indexPath.row].pairedMemberships {
                        paired += "\(i.displayName ?? "ParticipantX"),"
                    }
                    paired.removeLast()
                    
                    let alert = UIAlertController(title: "Mute all paired memberships", message: "This will mute \(paired)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Mute", style: .default, handler: { [weak self] _ in
                        guard let participant = self?.inMeeting[indexPath.row] else { return }
                        self?.muteParticipant(participant)
                    }))
                    alert.addAction(.dismissAction(withTitle: "Cancel"))
                    self.present(alert, animated: true)
                }
                else
                {
                    muteParticipant(inMeeting[indexPath.row])
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 {
            return true
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let contextItem = UIContextualAction(style: .normal, title: "Let In") { _, _, _  in
            var callMembershipsToLetIn: [CallMembership]
            callMembershipsToLetIn = [self.inLobby[indexPath.row]]
            self.call.letIn(callMembershipsToLetIn, completionHandler: { error in
                if error != nil {
                    print(error.debugDescription)
                }
            })
        }
        contextItem.backgroundColor = .momentumGreen50
        let swipeActions = UISwipeActionsConfiguration(actions: [contextItem])
        
        return swipeActions
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20.0
    }
    
    // MARK: Methods
    private func muteParticipant(_ participant: CallMembership) {
        if participant.isSelf {
            let alert = UIAlertController(title: "Not Supported", message: "Cannot mute self from participants list.", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
        } else {
            var isMuted = !participant.sendingAudio
            isMuted.toggle()
            call.setParticipantAudioMuteState(participantId: participant.personId ?? "", isMuted: isMuted)
        }
    }
    
    @objc private func muteAllParticipant(_ sender: UIButton) {
        if call.isCUCMCall || !call.isGroupCall {
            let alert = UIAlertController(title: "Not Supported", message: "Not supported for this call", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
        } else {
            mutedAll.toggle()
            muteAllButton.title = mutedAll ? "Unmute All" : "Mute All"
            call.setAllParticipantAudioMuteState(doMute: mutedAll)
        }
    }
    
    // MARK: Views and Constraints
    
    private lazy var muteAllButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Mute All", style: .done, target: self, action: #selector(muteAllParticipant(_:)))
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero)
        table.dataSource = self
        table.delegate = self
        table.register(ParticipantTableViewCell.self, forCellReuseIdentifier: self.kCellId)
        table.tableFooterView = UIView()
        table.allowsSelection = true
        table.rowHeight = 64
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private func setupViews() {
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        tableView.fillSuperView()
    }
    
    private func slideInStateView(slideInMsg: String) {
        let alert = UIAlertController(title: nil, message: slideInMsg, preferredStyle: .alert)
        self.present(alert, animated: true)
        let duration: Double = 2
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
            alert.dismiss(animated: true)
        }
    }
    
    func updateMeetingParticipant() {
        inMeeting = callParticipants.filter({ participant in
            participant.state == .joined
        })
        
        inLobby = callParticipants.filter({ participant in
            participant.state == .waiting
        })
        
        notInMeeting = callParticipants.filter({ participant in
            participant.state == .declined || participant.state == .idle || participant.state == .left
        })
        self.tableView.reloadData()
    }
    
    func participantsStatesProcess() {
        call.onCallMembershipChanged = { [weak self] membershipChangeType  in
            self?.callParticipants = self?.call.memberships ?? []
            if let strongSelf = self {
                switch membershipChangeType {
                /* This might be triggered when membership joined the call */
                case .joined(let membership):
                    strongSelf.slideInStateView(slideInMsg: (membership.displayName ?? (membership.sipUrl ?? "Unknown membership")) + " joined")
                /* This might be triggered when membership left the call */
                case .left(let membership):
                    strongSelf.slideInStateView(slideInMsg: (membership.displayName ?? (membership.sipUrl ?? "Unknown membership")) + " left")
                /* This might be triggered when membership declined the call */
                case .declined(let membership):
                    strongSelf.slideInStateView(slideInMsg: (membership.displayName ?? (membership.sipUrl ?? "Unknown membership")) + " declined")
                /* This might be triggered when membership mute/unmute the audio */
                case .sendingAudio(let membership):
                    if membership.sendingAudio {
                        strongSelf.slideInStateView(slideInMsg: (membership.displayName ?? (membership.sipUrl ?? "Unknown membership")) + " unmute audio")
                    } else {
                        strongSelf.slideInStateView(slideInMsg: (membership.displayName ?? (membership.sipUrl ?? "Unknown membership")) + " mute audio")
                    }
                /* This might be triggered when membership mute/unmute the video */
                case .sendingVideo(let membership):
                    if membership.sendingVideo {
                        strongSelf.slideInStateView(slideInMsg: (membership.displayName ?? (membership.sipUrl ?? "Unknown membership")) + " unmute video")
                    } else {
                        strongSelf.slideInStateView(slideInMsg: (membership.displayName ?? (membership.sipUrl ?? "Unknown membership")) + " mute video")
                    }
                /* This might be triggered when membership start/end the screen share */
                case .sendingScreenShare(let membership):
                    if membership.sendingScreenShare {
                        strongSelf.slideInStateView(slideInMsg: (membership.displayName ?? (membership.sipUrl ?? "Unknown membership")) + " share screen")
                    } else {
                        strongSelf.slideInStateView(slideInMsg: (membership.displayName ?? (membership.sipUrl ?? "Unknown membership")) + " stop share")
                    }
                /* This might be triggered when membership is waiting in lobby */
                case .waiting(let membership, _):
                    strongSelf.slideInStateView(slideInMsg: (membership.displayName ?? (membership.sipUrl ?? "Unknown membership")) + " inLobby")
                /* This might be triggered when membership is muted/unmuted by other membership, such as the host*/
                case .audioMutedControlled(let membership):
                    if membership.isAudioMutedControlled {
                        strongSelf.slideInStateView(slideInMsg: "\(membership.displayName ?? "") was muted by other")
                    } else {
                        strongSelf.slideInStateView(slideInMsg: "\(membership.displayName ?? "") was unmuted by other")
                    }
                @unknown default:
                    break
                }
                self?.inMeeting = []
                self?.inLobby = []
                self?.notInMeeting = []
                self?.updateMeetingParticipant()
                self?.tableView.reloadData()
            }
        }
    }
}
