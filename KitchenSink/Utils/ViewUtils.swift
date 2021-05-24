import UIKit

extension UIView {
    func fillSuperView(padded: CGFloat = 0) {
        guard let superview = superview else { fatalError("View doesn't have a superview") }
        fill(view: superview, padded: padded)
    }
    
    func fillWidth(of view: UIView, padded: CGFloat = 0) {
        leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padded).activate()
        trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padded).activate()
    }
    
    func fillHeight(of view: UIView, padded: CGFloat = 0) {
        topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padded).activate()
        bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padded).activate()
    }
    
    func fill(view: UIView, padded: CGFloat = 0) {
        fillWidth(of: view, padded: padded)
        fillHeight(of: view, padded: padded)
    }
    
    func alignCenter(in view: UIView? = nil) {
        guard let viewB = view ?? superview else { fatalError("No View to anchor") }
        centerXAnchor.constraint(equalTo: viewB.centerXAnchor).activate()
        centerYAnchor.constraint(equalTo: viewB.centerYAnchor).activate()
    }
    
    func setWidth(_ width: CGFloat) {
        widthAnchor.constraint(equalToConstant: width).activate()
    }
    
    func setHeight(_ height: CGFloat) {
        heightAnchor.constraint(equalToConstant: height).activate()
    }
    
    func setSize(width: CGFloat, height: CGFloat) {
        setWidth(width)
        setHeight(height)
    }
}
