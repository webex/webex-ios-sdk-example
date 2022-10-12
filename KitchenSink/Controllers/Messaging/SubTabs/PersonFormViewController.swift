import UIKit
import WebexSDK

class PersonFormViewController: UIViewController {
    var person: Person?
    var personRoles: [PersonRole] = []
    var siteUrls: [String] = []
    
    private let emailTextField: UITextField = {
        let txtField = UITextField()
        txtField.placeholder = "email ⃰"
        txtField.borderStyle = .roundedRect
        txtField.setHeight(30)
        return txtField
    }()
    
    private let displayNameTextField: UITextField = {
        let txtField = UITextField()
        txtField.placeholder = "displayName"
        txtField.borderStyle = .roundedRect
        txtField.setHeight(30)
        return txtField
    }()
    
    private let firstNameTextField: UITextField = {
        let txtField = UITextField()
        txtField.placeholder = "firstName"
        txtField.borderStyle = .roundedRect
        txtField.setHeight(30)
        return txtField
    }()
    
    private let lastNameTextField: UITextField = {
        let txtField = UITextField()
        txtField.placeholder = "lastName"
        txtField.borderStyle = .roundedRect
        txtField.setHeight(30)
        return txtField
    }()
    
    private let avatarTextField: UITextField = {
        let txtField = UITextField()
        txtField.placeholder = "avatar"
        txtField.borderStyle = .roundedRect
        txtField.setHeight(30)
        return txtField
    }()
    
    private let orgIdTextField: UITextField = {
        let txtField = UITextField()
        txtField.placeholder = "orgId"
        txtField.borderStyle = .roundedRect
        txtField.isEnabled = false
        txtField.setHeight(30)
        return txtField
    }()
    
    private let rolesTextField: UITextView = {
        let txtView = UITextView()
        txtView.text = "roles"
        txtView.addBorders()
        txtView.setHeight(50)
        return txtView
    }()
    
    private let siteUrlsTextField: UITextView = {
        let txtView = UITextView()
        txtView.text = "siteUrls"
        txtView.addBorders()
        txtView.setHeight(50)
        return txtView
    }()
    
    private let licensesTextField: UITextView = {
        let txtView = UITextView()
        txtView.text = "licenses"
        txtView.addBorders()
        txtView.setHeight(50)
        txtView.isEditable = false
        return txtView
    }()
    
    private lazy var createPersonButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(onCreatePersonTapped), for: .touchUpInside)
        view.setTitle("Create Person", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private let updatePersonButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(onUpdatePersonTapped), for: .touchUpInside)
        view.setTitle("Update Person", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private let formStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if person != nil {
            setupUpdatePersonForm()
        } else {
            setupCreatePersonForm()
        }
        
        setupConstraints()
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }
    
    func setupFormStackView() {
        formStackView.addArrangedSubview(emailTextField)
        formStackView.addArrangedSubview(displayNameTextField)
        formStackView.addArrangedSubview(firstNameTextField)
        formStackView.addArrangedSubview(lastNameTextField)
        formStackView.addArrangedSubview(avatarTextField)
        formStackView.addArrangedSubview(orgIdTextField)
        formStackView.addArrangedSubview(siteUrlsTextField)
        formStackView.addArrangedSubview(rolesTextField)
        
        if person != nil {
            formStackView.addArrangedSubview(licensesTextField)
        }
        view.addSubview(formStackView)
    }
    
    func setupCreatePersonForm() {
        setupFormStackView()
        view.addSubview(createPersonButton)
    }
    
    private func setupUpdatePersonForm() {
        guard let person = person else {
            fatalError("This should never happen")
        }
        
        emailTextField.text = person.emails?[0].toString()
        displayNameTextField.text = person.displayName
        firstNameTextField.text = person.firstName
        lastNameTextField.text = person.lastName
        avatarTextField.text = person.avatar
        orgIdTextField.text = person.orgId
        
        if person.roles.count > 0 {
            let rolesTxt = parseRoles(roles: person.roles)
            rolesTextField.text = rolesTxt
        }
        
        licensesTextField.text = person.licenses.joined(separator: ",\n")
        
        siteUrlsTextField.text = person.siteUrls.joined(separator: ",\n")
        
        setupFormStackView()
        view.addSubview(updatePersonButton)
    }
    
    func parseRoles(roles: [PersonRole]) -> String {
        var rolesStr = ""
        for role in roles {
            switch role {
            case .userAdministrator:
                rolesStr += "userAdministrator,\n"
            case .readOnlyAdministrator:
                rolesStr += "readOnlyAdministrator,\n"
            case .deviceAdministrator:
                rolesStr += "deviceAdministrator,\n"
            case .fullAdministrator:
                rolesStr += "fullAdministrator,\n"
            }
        }
        rolesStr.removeLast(2)
        return rolesStr
    }
    
    func setupConstraints() {
        var button: UIButton
        if person != nil {
            button = updatePersonButton
        } else {
            button = createPersonButton
        }
        
        formStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).activate()
        formStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).activate()
        formStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).activate()
        
        for subview in formStackView.subviews {
            subview.translatesAutoresizingMaskIntoConstraints = false
            subview.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).activate()
            subview.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).activate()
        }
        
        button.topAnchor.constraint(equalTo: formStackView.bottomAnchor, constant: 30).activate()
        button.centerXAnchor.constraint(equalTo: formStackView.centerXAnchor).activate()
        button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).activate()
        button.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).activate()
        button.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor , constant: -20).activate()
        
    }
    
    @objc func onCreatePersonTapped(_ sender: UIButton) {
        getSiteUrls()
        getPersonRoles()
        guard let email = emailTextField.text, !email.isEmpty, let displayName = displayNameTextField.text, let orgId = orgIdTextField.text, let avatar = avatarTextField.text, let firstName = firstNameTextField.text, let lastName = lastNameTextField.text else {
            let alert = UIAlertController(title: "Error", message: "Please fill in all required fields", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true, completion: nil)
            return
        }

        webex.people.create(email: EmailAddress.fromString(email)!, displayName: displayName, firstName: firstName, lastName: lastName, avatar: avatar, orgId: orgId, roles: personRoles, licenses: [], siteUrls: siteUrls, queue: nil, completionHandler: { [weak self] in
            var alertTitle: String = ""
            var alertBody: String = ""
            
            switch $0 {
            case .success(let person):
                alertTitle = "Person Created"
                alertBody = person.displayName ?? ""
            case .failure(let error):
                alertTitle = "Person Creation failed"
                alertBody = error.localizedDescription
            }
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: alertTitle, message: alertBody, preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Ok"))
                self?.siteUrls = []
                self?.personRoles = []
                self?.present(alert, animated: true)
            }
        })
    }
    
    @objc func onUpdatePersonTapped(_ sender: UIButton) {
        getSiteUrls()
        getPersonRoles()
        guard let person = person, let personId = person.id, let displayName = displayNameTextField.text, !displayName.isEmpty, let orgId = orgIdTextField.text, let avatar = avatarTextField.text, let email = emailTextField.text, let firstName = firstNameTextField.text, let lastName = lastNameTextField.text else {
            let alert = UIAlertController(title: "Error", message: "Please fill in all required fields", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        webex.people.update(personId: personId, email: EmailAddress.fromString(email), displayName: displayName, firstName: firstName, lastName: lastName, avatar: avatar, orgId: orgId, roles: personRoles, licenses: person.licenses, siteUrls: siteUrls, queue: nil, completionHandler: { [weak self] in
            var alertTitle: String = ""
            var alertBody: String = ""
            
            switch $0 {
            case .success(let person):
                alertTitle = "Person Updated"
                alertBody = person.displayName ?? ""
            case .failure(let error):
                alertTitle = "Person Update failed"
                alertBody = error.localizedDescription
            }
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: alertTitle, message: alertBody, preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Ok"))
                self?.siteUrls = []
                self?.personRoles = []
                self?.present(alert, animated: true)
            }
        })
    }
    
    func getSiteUrls() {
        if siteUrlsTextField.text == "siteUrls" {
            return
        }
        let urls = siteUrlsTextField.text.split(separator: ",")
        if urls.count > 0 {
            for url in urls {
                let updatedUrl = url.replacingOccurrences(of: "\n", with: "")
                siteUrls.append(updatedUrl)
            }
        }
    }
    
    func getPersonRoles() {
        let roles = rolesTextField.text.split(separator: ",")
        if roles.count > 0 {
            for role in roles {
                let updatedRole = role.replacingOccurrences(of: "\n", with: "")
                switch (updatedRole) {
                case "userAdministrator":
                    personRoles.append(.userAdministrator)
                case "readOnlyAdministrator":
                    personRoles.append(.readOnlyAdministrator)
                case "deviceAdministrator":
                    personRoles.append(.deviceAdministrator)
                case "fullAdministrator":
                    personRoles.append(.fullAdministrator)
                default:
                    break
                }
            }
        }
    }
}
