import WebexSDK
class NewWebhookFormViewController: UIPageViewController {
    var webhook: Webhook?
    
    let nameTF: UITextField = {
        let txtField = UITextField()
        txtField.backgroundColor = .white
        txtField.placeholder = "Webhook name"
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    let targetUrlTF: UITextField = {
        let txtField = UITextField()
        txtField.backgroundColor = .white
        txtField.placeholder = "targetUrl"
        let random = Int.random(in: 1..<30)
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    let secretTF: UITextField = {
        let txtField = UITextField()
        txtField.backgroundColor = .white
        txtField.placeholder = "secret"
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    let statusTF: UITextField = {
        let txtField = UITextField()
        txtField.backgroundColor = .white
        txtField.placeholder = "status"
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    private let resourceTF: UITextField = {
        let txtField = UITextField()
        txtField.backgroundColor = .white
        txtField.placeholder = "resource"
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    private let eventTF: UITextField = {
        let txtField = UITextField()
        txtField.backgroundColor = .white
        txtField.placeholder = "event"
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    private let filterTF: UITextField = {
        let txtField = UITextField()
        txtField.backgroundColor = .white
        txtField.placeholder = "filter"
        txtField.borderStyle = .roundedRect
        return txtField
    }()
    
    private let createWebhookButton: UIButton = {
        let btn = UIButton(type: .roundedRect)
        btn.setTitle("Create Webhook", for: .normal)
        btn.setHeight(30)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(onCreateWebhookTapped), for: .touchUpInside)
        return btn
    }()
    
    private let updateWebhookButton: UIButton = {
        let btn = UIButton(type: .roundedRect)
        btn.setTitle("Update Webhook", for: .normal)
        btn.setHeight(30)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(onUpdateWebhookTapped), for: .touchUpInside)
        return btn
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
        formStackView.addArrangedSubview(filterTF)
        formStackView.addArrangedSubview(secretTF)
        formStackView.addArrangedSubview(createWebhookButton)
        view.addSubview(formStackView)
    }
    
    func setupConstraints() {
        formStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).activate()
        formStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).activate()
        formStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).activate()
        formStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).activate()
        
        formStackView.heightAnchor.constraint(equalToConstant: view.frame.height / 3).activate()
        for subview in formStackView.subviews {
            subview.translatesAutoresizingMaskIntoConstraints = false
            subview.setWidth(250)
            subview.setHeight(30)
        }
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
        formStackView.addArrangedSubview(updateWebhookButton)
        view.addSubview(formStackView)
    }
    
    @objc func onCreateWebhookTapped(_ sender: UIButton) {
        guard let name = nameTF.text, let targetUrl = targetUrlTF.text, let resource = resourceTF.text, let event = eventTF.text else {
            return
        }
        
        webex.webhooks.create(name: name, targetUrl: targetUrl, resource: resource, event: event, filter: filterTF.text, secret: secretTF.text) { [weak self] in
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
