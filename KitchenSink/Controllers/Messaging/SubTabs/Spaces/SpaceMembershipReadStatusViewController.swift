import UIKit
import WebexSDK

final class SpaceMembershipReadStatusViewController: BasicTableViewController<MembershipReadStatus, ContactTableViewCell> {
    private let spaceId: String
    
    init(spaceId: String) {
        self.spaceId = spaceId
        super.init(placeholderText: "No Members in Space")
        title = "Space Membership Read Status"
        registerMembershipCallBackWithPayload()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func refreshList() {
        webex.memberships.listWithReadStatus(spaceId: spaceId, queue: .global(qos: .default)) { [weak self] in
            self?.listItems = $0.data ?? []
        }
    }
    
    func registerMembershipCallBackWithPayload() {
        webex.memberships.onEventWithPayload = { [self] event, id in
            print(id)
            switch event {
            case .created:
                break
            case .deleted:
                break
            case .update:
                break
            case .messageSeen(let membership, lastSeenMessage: let lastSeenId):
                print("Person with id: \(membership.personId ?? "") updated last seen message to \(lastSeenId)")
                self.refreshList()
            @unknown default:
                self.refreshList()
            }
        }
    }
}

extension SpaceMembershipReadStatusViewController {
    // MARK: UITableViewDatasource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.reuseIdentifier, for: indexPath) as? ContactTableViewCell else {
            return UITableViewCell()
        }
        let membership = listItems[indexPath.row]
        cell.setupCell(name: "Read Status", description: membership.displayValue)
        return cell
    }
}

extension SpaceMembershipReadStatusViewController {
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension MembershipReadStatus {
    var displayValue: String {
        return "Membership: \(member.displayValue)\n Last Seen Date:\((lastSeenDate?.description).valueOrEmpty)"
    }
}
