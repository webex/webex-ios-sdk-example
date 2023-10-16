import UIKit
import WebexSDK

class ClosedCaptionsViewController: UIViewController, UITableViewDataSource {
    
    var items: [CaptionItem] = []
    var call: Call?
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero)
        table.dataSource = self
        table.delegate = self
        table.tableFooterView = UIView()
        table.allowsSelection = true
        table.rowHeight = 60
        table.translatesAutoresizingMaskIntoConstraints = false
        table.accessibilityIdentifier = "tableView"
        return table
    }()
    
    private lazy var headerLanguageSelection: UILabel = {
        let view = UILabel()
        view.text = "Closed Captions"
        view.font = UIFont.systemFont(ofSize: 20)
        view.textAlignment = .center
        view.translatesAutoresizingMaskIntoConstraints = false
        view.accessibilityIdentifier = "headerLanguageSelection"
        return view
    }()
    
    init(call: Call?) {
        self.call = call
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        title = "Spoken Language Selection"
        navigationController?.navigationBar.prefersLargeTitles = true
        setupViews()
        setupConstraints()
        items = call?.getClosedCaptions() ?? []
        call?.onClosedCaptionArrived = { item in
            if item.isFinal {
                self.items.append(item)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
        self.tableView.reloadData()
    }
    
    private func setupViews() {
        view.addSubview(headerLanguageSelection)
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
        headerLanguageSelection.heightAnchor.constraint(equalToConstant: 60)])
        headerLanguageSelection.fillWidth(of: view)
        tableView.fillWidth(of: view)
        tableView.fillHeight(of: view, padded: 80)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "CheckmarkCell")
        let item = items[indexPath.row]
        cell.textLabel?.text = item.displayName
        cell.detailTextLabel?.text = item.content
        return cell
    }
}

extension ClosedCaptionsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}
