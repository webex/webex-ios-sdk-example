import UIKit

class DialButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel?.font = .preferredFont(forTextStyle: .title1)
        setTitleColor(.labelColor, for: .normal)
        backgroundColor = .lighterGrayColor
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let diameter = min(bounds.width, bounds.height)
        layer.cornerRadius = diameter / 2
    }
}
