import UIKit
import WebexSDK

protocol LanguageSelectionViewControllerDelegate: AnyObject
{
    func languageSelected(language: LanguageItem)
}

class LanguageSelectionViewController: UIViewController, UITableViewDataSource {
    
    var items: [LanguageItem] = []
    weak var delegate: LanguageSelectionViewControllerDelegate?
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
        view.text = "Select Language"
        view.font = UIFont.systemFont(ofSize: 20)
        view.textAlignment = .center
        view.translatesAutoresizingMaskIntoConstraints = false
        view.accessibilityIdentifier = "headerLanguageSelection"
        return view
    }()
    
    init(items: [LanguageItem]) {
        self.items = items
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
        cell.textLabel?.text = item.languageTitle
        cell.detailTextLabel?.text = item.languageTitleInEnglish
        if item.isSelected {
            cell.accessoryType = .checkmark
        }
        return cell
    }
    
}

extension LanguageSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true)
        delegate?.languageSelected(language: items[indexPath.row])
    }
}
