import UIKit

class MessagingViewController: UIPageViewController {
    private let titles = ["Teams", "Spaces", "People", "Memberships"]
    private var currentIndex = 0
    private let controllers: [NavigationItemSetupProtocol] = [
        TeamsViewController(),
        MessagingSpacesViewController(),
        PeopleViewController(),
        SpaceMembershipViewController()
    ]
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = .backgroundColor
        navigationController?.view.backgroundColor = .backgroundColor
        view.backgroundColor = .backgroundColor
        navigationItem.titleView = segmentedControl
        segmentedControl.selectedSegmentIndex = currentIndex
        switchToTab(at: currentIndex)
    }
    
    private func switchToTab(at index: Int) {
        guard index < controllers.count && index >= 0 else { return }
        let direction: NavigationDirection = index > currentIndex ? .forward : .reverse
        let controller = controllers[index]
        setViewControllers([controller], direction: direction, animated: false)
        navigationItem.setRightBarButtonItems(controller.rightBarButtonItems, animated: true)
        title = titles[index]
        currentIndex = index
    }
    
    @objc private func handleSegmentChange(_ control: UISegmentedControl) {
        switchToTab(at: control.selectedSegmentIndex)
    }
    
    private lazy var segmentedControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl(items: titles)
        segmentControl.addTarget(self, action: #selector(self.handleSegmentChange(_:)), for: .valueChanged)
        segmentControl.accessibilityIdentifier = "MessagingSegmentedControl"
        return segmentControl
    }()
}
