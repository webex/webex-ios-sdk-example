import UIKit
import WebexSDK

class ParticipantListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: Properties
    private let kCellId = "ParticipantCell"
    private var callParticipants: [CallMembership] = []
    private let call: Call
    private var mutedAll: Bool = false
    
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
        self.tableView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setRightBarButton(muteAllButton, animated: true)
        view.backgroundColor = .backgroundColor
        setupViews()
        setupConstraints()
        participantsStatesProcess()
    }
    
    // MARK: TableView Datasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return callParticipants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: kCellId, for: indexPath) as? ParticipantTableViewCell else {
            return UITableViewCell()
        }
        let participant = callParticipants[indexPath.row]
        cell.setupCell(name: participant.displayName ?? "", isAudioMuted: !participant.sendingAudio)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        muteParticipant(callParticipants[indexPath.row])
    }
    
    // MARK: Methods
    private func muteParticipant(_ participant: CallMembership) {
        var isMuted = !participant.sendingAudio
        isMuted.toggle()
        call.setParticipantAudioMuteState(participantId: participant.personId ?? "", isMuted: isMuted)
    }
    
    @objc private func muteAllParticipant(_ sender: UIButton) {
        mutedAll.toggle()
        muteAllButton.title = mutedAll ? "Unmute All" : "Mute All"
        call.setAllParticipantAudioMuteState(doMute: mutedAll)
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
        let duration: Double = 5
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
            alert.dismiss(animated: true)
        }
    }
    
    func participantsStatesProcess() {
        call.onCallMembershipChanged = { [weak self] membershipChangeType  in
            self?.callParticipants = self?.call.memberships ?? []
            if let strongSelf = self {
                switch membershipChangeType {
                /* This might be triggered when membership joined the call */
                case .joined(let memberShip):
                    strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " joined")
                /* This might be triggered when membership left the call */
                case .left(let memberShip):
                    strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " left")
                /* This might be triggered when membership declined the call */
                case .declined(let memberShip):
                    strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " declined")
                /* This might be triggered when membership mute/unmute the audio */
                case .sendingAudio(let memberShip):
                    if memberShip.sendingAudio {
                        strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " unmute audio")
                    } else {
                        strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " mute audio")
                    }
                /* This might be triggered when membership mute/unmute the video */
                case .sendingVideo(let memberShip):
                    if memberShip.sendingVideo {
                        strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " unmute video")
                    } else {
                        strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " mute video")
                    }
                /* This might be triggered when membership start/end the screen share */
                case .sendingScreenShare(let memberShip):
                    if memberShip.sendingScreenShare {
                        strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " share screen")
                    } else {
                        strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " stop share")
                    }
                /* This might be triggered when membership is waiting in lobby */
                case .waiting(let memberShip, _):
                    strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " inLobby")
                /* This might be triggered when membership is muted/unmuted by other membership, such as the host*/
                case .audioMutedControlled(let memberShip):
                    if memberShip.isAudioMutedControlled {
                        strongSelf.slideInStateView(slideInMsg: "\(memberShip.email ?? "") was muted by other")
                    } else {
                        strongSelf.slideInStateView(slideInMsg: "\(memberShip.email ?? "") was unmuted by other")
                    }
                @unknown default:
                    break
                }
                self?.tableView.reloadData()
            }
        }
    }
}
