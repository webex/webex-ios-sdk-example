import UIKit

class WebhookTableViewCell: UITableViewCell, ReusableCell {
    typealias ButtonActionHandler = () -> Void
    private var buttonActionHandler: ButtonActionHandler?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        buttonActionHandler = nil
    }
    
    func setupCell(name: String, buttonActionHandler handler: @escaping ButtonActionHandler) {
        textLabel?.numberOfLines = 2
        textLabel?.text = name
        buttonActionHandler = handler
        addButtonToAccessoryView()
    }
    
    func setupCell(name: String?, description: String?) {
        detailTextLabel?.numberOfLines = 0
        detailTextLabel?.text = description
        textLabel?.text = name
    }
    
    @objc private func handleButtonAction(_ sender: UIButton) {
        buttonActionHandler?()
    }
    
    private func addButtonToAccessoryView() {
        let button =  UIButton()
        button.frame.size = CGSize(width: 44, height: 44)
        button.addTarget(self, action: #selector(handleButtonAction), for: .touchUpInside)
        button.accessibilityIdentifier = "actionButton"
        accessoryView = button
    }
}
