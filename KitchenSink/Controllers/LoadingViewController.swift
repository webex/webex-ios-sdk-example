import UIKit

class LoadingViewController: UIViewController {
    var activityIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .large)
         } else {
            return UIActivityIndicatorView(style: .whiteLarge)
         }
    }()
    
    var titleLabel = UILabel()
    init(text: String = "") {
        super.init(nibName: nil, bundle: nil)
        titleLabel.text = text
        titleLabel.textAlignment = .center
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        view.addSubview(titleLabel)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor).isActive = true
        titleLabel.fillWidth(of: view)
        self.activityIndicator.startAnimating()
    }
}
