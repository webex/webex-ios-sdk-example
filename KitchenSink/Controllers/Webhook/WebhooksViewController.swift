import WebexSDK

class WebhooksViewController: UITableViewController {
    // MARK: Properties
    
    private let placeholderLabel = UILabel.placeholderLabel(withText: "No Webhooks configured")
    
    var listItems: [Webhook] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.backgroundView = self.listItems.isEmpty ? self.placeholderLabel : nil
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: Initializers
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshList()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = .backgroundColor
        navigationController?.view.backgroundColor = .backgroundColor
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addWebhookTapped))
        configureTable()
    }
    
    // MARK: Actions
    @objc private func addWebhookTapped() {
        navigationController?.pushViewController(NewWebhookFormViewController(), animated: true)
    }
    
    private func setupViews() {
    }
    
    private func setupConstraints() {
    }
    
    func refreshList() {
        webex.webhooks.list(max: nil, queue: DispatchQueue.global(qos: .default)) { [weak self] in
            switch $0 {
            case .success(let webhooks):
                self?.listItems = webhooks
            case .failure(let error):
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error listing webhooks", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(.dismissAction(withTitle: "Ok"))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
}

extension WebhooksViewController {
    // MARK: UITableViewDatasource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WebhookTableViewCell.reuseIdentifier, for: indexPath) as? WebhookTableViewCell else {
            return UITableViewCell()
        }
        let webhookItem = listItems[indexPath.row]
        cell.setupCell(name: webhookItem.name, description: webhookItem.targetUrl)
        
        return cell
    }
}

extension WebhooksViewController {
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let alertController = UIAlertController.actionSheetWith(title: "Webhook Actions", message: nil, sourceView: self.view)
        if let webhookId = listItems[indexPath.row].id {
            alertController.addAction(UIAlertAction(title: "Fetch Webhook by Id", style: .default) { [weak self] _ in
                webex.webhooks.get(webhookId: webhookId, queue: DispatchQueue.global(qos: .default)) { [weak self] in
                    var alertTitle: String = ""
                    var alertBody: String = ""
                    
                    switch $0 {
                    case .success(let webhook):
                        
                        alertTitle = "Fetched Webhook: " + (webhook.id ?? "")
                        alertBody = "Resource:" + (webhook.resource ?? "")
                        
                    case .failure(let error):
                        
                        alertTitle = "Fetch Webhook by Id failed"
                        alertBody = error.localizedDescription
                    }
                    
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: alertTitle, message: alertBody, preferredStyle: .alert)
                        alert.addAction(.dismissAction(withTitle: "Ok"))
                        self?.present(alert, animated: true)
                    }
                }
            })
            
            alertController.addAction(UIAlertAction(title: "Update Webhook", style: .default) { [weak self] _ in
                guard let self = self else { return }
                let webhook = self.listItems[indexPath.row]
                let updateWebhookFormVC = NewWebhookFormViewController()
                updateWebhookFormVC.webhook = webhook
                self.navigationController?.pushViewController(updateWebhookFormVC, animated: true)
            })
            
            alertController.addAction(UIAlertAction(title: "Delete Webhook", style: .default) { [weak self] _ in
                webex.webhooks.delete(webhookId: webhookId) { [weak self] in
                    switch $0 {
                    case .success:
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Deleted Webhook", message: "", preferredStyle: .alert)
                            alert.addAction(.dismissAction(withTitle: "Ok"))
                            self?.present(alert, animated: true)
                            self?.refreshList()
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Unable to delete Webhook", message: error.localizedDescription, preferredStyle: .alert)
                            alert.addAction(.dismissAction(withTitle: "Ok"))
                            self?.present(alert, animated: true)
                        }
                    }
                }
            })
            
            alertController.addAction(.dismissAction(withTitle: "Cancel"))
        }
        present(alertController, animated: true)
    }
}

extension WebhooksViewController {
    // MARK: Private Methods
    private func configureTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WebhookTableViewCell.self, forCellReuseIdentifier: WebhookTableViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
}
