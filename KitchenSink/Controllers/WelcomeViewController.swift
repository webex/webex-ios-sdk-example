import Foundation
import SwiftUI
import UIKit

class WelcomeViewController: UIViewController {

    var logoImageView: UIImageView!
    var buttonStackView: UIStackView!

    private lazy var oldUIButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(oldButtonTapped), for: .touchUpInside)
        view.setTitle("Open old UI", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var newUIButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(newButtonTapped), for: .touchUpInside)
        view.setTitle("Open new UI", for: .normal)
        view.accessibilityIdentifier = "swiftUIButton"
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumPink50
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Enable dark and light mode
        overrideUserInterfaceStyle = .light

        // Set up the image view
        logoImageView = UIImageView(image: UIImage(named: "logo"))
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.layer.cornerRadius = 5
        view.addSubview(logoImageView)

        // Create the stack view and add the buttons
        buttonStackView = UIStackView(arrangedSubviews: [oldUIButton, newUIButton])
        buttonStackView.axis = .vertical
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 20
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStackView)

        // Apply constraints
        setupConstraints()
    }

    func createButton(withTitle title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 10
        button.backgroundColor = .systemBlue
        return button
    }

    private var keyWindow: UIWindow? {
        return UIApplication.shared.windows.first { $0.isKeyWindow }
    }

    @objc func oldButtonTapped() {
        DispatchQueue.main.async {
            guard let window = self.keyWindow else { return }
            window.rootViewController = UINavigationController(rootViewController: LoginViewController())
            window.makeKeyAndVisible()
        }
        return
    }

    @objc func newButtonTapped() {
        if #available(iOS 16.0, *) {
            DispatchQueue.main.async {
                let loginView = LoginView()
                let hostingController = UIHostingController(rootView: loginView)

                hostingController.sizingOptions = .intrinsicContentSize
                hostingController.modalPresentationStyle = .fullScreen
                self.present(hostingController, animated: true)
            }
        } else {
            let errorAlert = UIAlertController(title: "Error", message: "Minimum iOS 16 required", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction.dismissAction())
            self.present(errorAlert, animated: true, completion: nil)
        }
    }

    func setupConstraints() {
        // Constraints for logoImageView
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            logoImageView.widthAnchor.constraint(equalToConstant: 150),
            logoImageView.heightAnchor.constraint(equalToConstant: 150)
        ])

        // Constraints for buttonStackView
        NSLayoutConstraint.activate([
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 50),
            buttonStackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
    }
}
