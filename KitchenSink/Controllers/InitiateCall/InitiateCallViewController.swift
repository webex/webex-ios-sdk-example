import UIKit

class InitiateCallViewController: UIPageViewController {
    private let titles = ["Call", "Search", "History", "Spaces"]
    private let controllers = [
        DialCallViewController(),
        SearchContactViewController(),
        HistoryCallViewController(),
        CallingSpacesListViewController()
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
        navigationItem.titleView = initateCallSegmentControl
        initateCallSegmentControl.selectedSegmentIndex = 0
        switchToTab(at: 0)
    }
    
    private func switchToTab(at index: Int) {
        guard index < controllers.count && index >= 0 else { return }
        setViewControllers([controllers[index]], direction: .forward, animated: false)
        title = titles[index]
    }
    
    @objc private func handleSegmentChange(_ control: UISegmentedControl) {
        switchToTab(at: control.selectedSegmentIndex)
    }
    
    private lazy var initateCallSegmentControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl(items: titles)
        segmentControl.addTarget(self, action: #selector(self.handleSegmentChange(_:)), for: .valueChanged)
        segmentControl.accessibilityIdentifier = "initateCallSegmentControl"
        return segmentControl
    }()
}
