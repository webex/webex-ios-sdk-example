import UIKit

protocol DialPadViewDelegate: AnyObject {
    func dialPadView(_ dialPadView: DialPadView, didSelect key: String)
}

class DialPadView: UIView {
    weak var delegate: DialPadViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func getDialStringValue(for number: Int) -> String {
        switch number {
        case _ where number < 10: return String(number)
        case 11: return "+"
        case 12: return "#"
        default: return "-"
        }
    }
    
    @objc private func handleKeyPress(_ button: DialButton) {
        delegate?.dialPadView(self, didSelect: getDialStringValue(for: button.tag))
    }
    
    private func getDialButton(for number: Int) -> DialButton {
        return {
            let title = self.getDialStringValue(for: number)
            let button = DialButton(frame: .zero)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle(title, for: .normal)
            button.tag = number
            button.addTarget(self, action: #selector(self.handleKeyPress(_:)), for: .touchUpInside)
            button.heightAnchor.constraint(equalTo: button.widthAnchor).activate()
            return button
            }()
    }
    
    private var stackView: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 20
        return stack
    }()
    
    private var rowStacks: [UIStackView] = (0..<4).map { _ in
        return {
            let stack = UIStackView(frame: .zero)
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.axis = .horizontal
            stack.distribution = .fillEqually
            stack.spacing = 20
            return stack
        }()
    }
    
    private func setupViews() {
        addSubview(stackView)
        rowStacks.forEach { stackView.addArrangedSubview($0) }
        [1, 2, 3].forEach { rowStacks[0].addArrangedSubview(getDialButton(for: $0)) }
        [4, 5, 6].forEach { rowStacks[1].addArrangedSubview(getDialButton(for: $0)) }
        [7, 8, 9].forEach { rowStacks[2].addArrangedSubview(getDialButton(for: $0)) }
        [11, 0, 12].forEach { rowStacks[3].addArrangedSubview(getDialButton(for: $0)) }
    }
    
    private func setupConstraints() {
        stackView.fillSuperView()
    }
}
