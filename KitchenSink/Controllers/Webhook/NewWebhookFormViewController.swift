import WebexSDK
class NewWebhookFormViewController: UIPageViewController {
    var webhook: Webhook?
    
    let nameTF: UITextField = {
        let txtField = UITextField()
        txtField.placeholder = "Webhook name ⃰"
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    let targetUrlTF: UITextField = {
        let txtField = UITextField()
        txtField.placeholder = "targetUrl ⃰"
        let random = Int.random(in: 1..<30)
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    let secretTF: UITextField = {
        let txtField = UITextField()
        txtField.placeholder = "secret"
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    let statusTF: UITextField = {
        let txtField = UITextField()
        txtField.placeholder = "status"
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    private let resourceTF: UITextField = {
        let txtField = UITextField()
        txtField.placeholder = "resource ⃰"
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    private let eventTF: UITextField = {
        let txtField = UITextField()
        txtField.placeholder = "event ⃰"
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    private let enableFilterTFSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = false
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(enableFilterTFSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let enableFilterTFLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "Enable filter"
        label.text = "Enable filter"
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    private lazy var enableFilterTFStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [enableFilterTFLabel, enableFilterTFSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()

    private let filterTF: UITextField = {
        let txtField = UITextField()
        txtField.text = nil
        txtField.isEnabled = false
        txtField.placeholder = "filter"
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    private lazy var createWebhookButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(onCreateWebhookTapped), for: .touchUpInside)
        view.setTitle("Create Webhook", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.setWidth(250)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private let updateWebhookButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(onUpdateWebhookTapped), for: .touchUpInside)
        view.setTitle("Update Webhook", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.setWidth(250)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private let formStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 30
        stack.alignment = .center
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if webhook != nil {
            setupUpdateWebhookForm()
        } else {
            setupCreateWebhookForm()
        }
        
        setupConstraints()
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }
    
    func setupCreateWebhookForm() {
        formStackView.addArrangedSubview(nameTF)
        formStackView.addArrangedSubview(targetUrlTF)
        formStackView.addArrangedSubview(resourceTF)
        formStackView.addArrangedSubview(eventTF)
        formStackView.addArrangedSubview(enableFilterTFStackView)
        formStackView.addArrangedSubview(filterTF)
        formStackView.addArrangedSubview(secretTF)
        view.addSubview(formStackView)
        view.addSubview(createWebhookButton)
    }
    
    func setupConstraints() {
        var stackHeight: CGFloat
        var button: UIButton
        if webhook != nil {
            button = updateWebhookButton
            stackHeight = 220
        } else {
            button = createWebhookButton
            stackHeight = 400
        }
        
        formStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).activate()
        formStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).activate()
        formStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).activate()
        formStackView.setHeight(stackHeight)

        for subview in formStackView.subviews {
            subview.translatesAutoresizingMaskIntoConstraints = false
            subview.setWidth(250)
            subview.setHeight(30)
        }
        
        button.topAnchor.constraint(equalTo: formStackView.bottomAnchor, constant: 30).activate()
        button.centerXAnchor.constraint(equalTo: formStackView.centerXAnchor).activate()
    }
    
    private func setupUpdateWebhookForm() {
        guard let webhook = webhook else {
            fatalError("This should never happen")
        }
        
        nameTF.text = webhook.name
        targetUrlTF.text = webhook.targetUrl
        secretTF.text = webhook.secret
        statusTF.text = webhook.status
        
        formStackView.addArrangedSubview(nameTF)
        formStackView.addArrangedSubview(targetUrlTF)
        formStackView.addArrangedSubview(secretTF)
        formStackView.addArrangedSubview(statusTF)
        view.addSubview(formStackView)
        view.addSubview(updateWebhookButton)
    }
    
    @objc func enableFilterTFSwitchValueDidChange(_ sender: UISwitch) {
        filterTF.isEnabled = sender.isOn
    }

    @objc func onCreateWebhookTapped(_ sender: UIButton) {
        var filter: String?
        guard let name = nameTF.text, let targetUrl = targetUrlTF.text, let resource = resourceTF.text, let event = eventTF.text, !name.isEmpty, !targetUrl.isEmpty, !resource.isEmpty, !event.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Please fill in all required fields", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if enableFilterTFSwitch.isOn {
            guard let text = filterTF.text, !text.isEmpty else {
                let alert = UIAlertController(title: "Error", message: "filter cannot be empty", preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Ok"))
                self.present(alert, animated: true, completion: nil)
                return
            }
            filter = filterTF.text
        }
        
        webex.webhooks.create(name: name, targetUrl: targetUrl, resource: resource, event: event, filter: filter, secret: secretTF.text) { [weak self] in
            var alertTitle: String = ""
            var alertBody: String = ""
            
            switch $0 {
            case .success(let webhook):
                alertTitle = "Webhook Created"
                alertBody = webhook.id ?? ""
            case .failure(let error):
                alertTitle = "Webhook Creation failed"
                alertBody = error.localizedDescription
            }
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: alertTitle, message: alertBody, preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Ok"))
                self?.present(alert, animated: true)
            }
        }
    }
    
    @objc func onUpdateWebhookTapped(_ sender: UIButton) {
        guard let webhook = webhook, let webhookId = webhook.id, let name = nameTF.text, let targetUrl = targetUrlTF.text else {
            return
        }
        
        webex.webhooks.update(webhookId: webhookId, name: name, targetUrl: targetUrl, secret: secretTF.text, status: statusTF.text) { [weak self] in
            var alertTitle: String = ""
            var alertBody: String = ""
            
            switch $0 {
            case .success(let webhook):
                
                alertTitle = "Webhook Updated"
                alertBody = webhook.id ?? ""
                
            case .failure(let error):
                
                alertTitle = "Webhook Update failed"
                alertBody = error.localizedDescription
            }
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: alertTitle, message: alertBody, preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Ok"))
                self?.present(alert, animated: true)
            }
        }
    }
}
