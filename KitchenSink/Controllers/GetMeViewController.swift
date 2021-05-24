import UIKit
import WebexSDK
class GetMeViewController: UIViewController {
    lazy var avatarImage: UIImageView = {
        let avatar = UIImageView(frame: .zero)
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.contentMode = .scaleAspectFit
        return avatar
    }()
    
    lazy var idLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 16)
        label.numberOfLines = 3
        return label
    }()
    
    lazy var createdLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 16)
        label.numberOfLines = 3
        return label
    }()
    
    lazy var nickNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 16)
        return label
    }()
    
    lazy var firstNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 16)
        return label
    }()
    
    lazy var lastNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 16)
        return label
    }()
    
    lazy var orgIdLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 16)
        label.numberOfLines = 3
        return label
    }()
    
    lazy var displayNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 16)
        return label
    }()
    
    lazy var lastActivityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 16)
        return label
    }()
    
    lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 16)
        return label
    }()
    
    lazy var typeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 16)
        return label
    }()
    
    lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 16)
        return label
    }()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [idLabel, displayNameLabel, nickNameLabel, firstNameLabel, lastNameLabel, emailLabel, createdLabel, orgIdLabel, lastActivityLabel, statusLabel, typeLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 20.0
        return stackView
    }()
    
    func setupViews() {
        view.addSubview(avatarImage)
        view.addSubview(stackView)
    }
    
    func setupConstraints() {
        avatarImage.setSize(width: 50, height: 50)
        avatarImage.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        avatarImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).activate()

        stackView.topAnchor.constraint(equalTo: avatarImage.topAnchor, constant: 20).activate()
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).activate()
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20).activate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .popover
        view.backgroundColor = .backgroundColor
        title = "Get My Details"
        getData()
        setupViews()
        setupConstraints()
    }
    
    public func getData() {
        webex.people.getMe(completionHandler: { [weak self] result in
            guard let person = result.data else { return }
            self?.idLabel.text = "Person Id:  \(person.id ?? "")"
            self?.createdLabel.text = "Created On:  \(person.created ?? Date())"
            self?.displayNameLabel.text = "Display Name:  \(person.displayName ?? "")"
            self?.nickNameLabel.text = "Nick Name:  \(person.nickName ?? "")"
            self?.firstNameLabel.text = "First Name:  \(person.firstName ?? "")"
            self?.lastNameLabel.text = "Last Name:  \(person.lastName ?? "")"
            self?.orgIdLabel.text = "Org Id:  \(person.orgId ?? "")"
            self?.lastActivityLabel.text = "Last Activityt:  \(person.lastActivity ?? Date())"
            self?.statusLabel.text = "Status:  \(person.status ?? "")"
            self?.typeLabel.text = "Type:  \(person.type ?? "")"
            var emailIds: String = ""
            let emailCount = person.emails?.count ?? 0
            
            for i in 0..<emailCount {
                emailIds.append("\(person.emails?[i].toString() ?? "") ")
            }
            self?.emailLabel.text = "Email Id:  \(emailIds)"
            self?.avatarImage.image = person.avatar != nil ? UIImage(contentsOfFile: person.avatar ?? "") : UIImage(named: "people")
        })
    }
}
