import UIKit

class InitiateCallViewController: UIPageViewController {
    private let titles = ["Call", "Search", "History", "Spaces", "Meetings"]
    private let controllers:[NavigationItemSetupProtocol] = [
        DialCallViewController(),
        SearchContactViewController(),
        HistoryCallViewController(),
        CallingSpacesListViewController(),
        CalendarMeetingsViewController()
    ]
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        navigationItem.titleView = initiateCallSegmentControl
        initiateCallSegmentControl.selectedSegmentIndex = 0
        switchToTab(at: 0)
    }
    
    private func switchToTab(at index: Int) {
        guard index < controllers.count && index >= 0 else { return }
        let controller = controllers[index]
        setViewControllers([controller], direction: .forward, animated: false)
        navigationItem.setRightBarButtonItems(controller.rightBarButtonItems, animated: true)
        title = titles[index]
    }
    
    @objc private func handleSegmentChange(_ control: UISegmentedControl) {
        switchToTab(at: control.selectedSegmentIndex)
    }
    
    private lazy var initiateCallSegmentControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl(items: titles)
        segmentControl.addTarget(self, action: #selector(self.handleSegmentChange(_:)), for: .valueChanged)
        segmentControl.accessibilityIdentifier = "initiateCallSegmentControl"
        return segmentControl
    }()
}
