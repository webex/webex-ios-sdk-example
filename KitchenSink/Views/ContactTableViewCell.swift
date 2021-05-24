import UIKit

class ContactTableViewCell: UITableViewCell, ReusableCell {
    typealias ButtonActionHandler = () -> Void
    private var buttonActionHandler: ButtonActionHandler?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    enum ButtonStyle {
        case call, messaging
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        buttonActionHandler = nil
    }
    
    func setupCell(name: String, buttonActionHandler handler: @escaping ButtonActionHandler, buttonStyle: ButtonStyle = .call) {
        textLabel?.numberOfLines = 2
        textLabel?.text = name
        buttonActionHandler = handler
        addButtonToAccessoryView(withStyle: buttonStyle)
    }
    
    func setupCell(name: String?, description: String?) {
        detailTextLabel?.numberOfLines = 0
        detailTextLabel?.text = description
        textLabel?.text = name
    }
    
    @objc private func handleButtonAction(_ sender: UIButton) {
        buttonActionHandler?()
    }
    
    private func addButtonToAccessoryView(withStyle style: ButtonStyle) {
        let button = style == .call ? CallButton(style: .outlined, size: .small, type: .connectCall) : UIButton()
        button.frame.size = CGSize(width: 44, height: 44)
        button.addTarget(self, action: #selector(handleButtonAction), for: .touchUpInside)
        button.accessibilityIdentifier = "actionButton"
        accessoryView = button
    }
}
