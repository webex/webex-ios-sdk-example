import UIKit
import WebexSDK

protocol FilterSpacesDelegate: AnyObject {
    func didUpdateListParameters(teamId: String?, maxNumberOfSpaces: Int?, spaceType: SpaceType?, sortType: SpaceSortType?, spaceValueType: MessagingSpacesViewController.SpaceValue)
}

final class FilterSpacesViewController: UIViewController {
    private let headerLabel: UILabel = {
        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = "Filter Spaces"
        headerLabel.font = .boldSystemFont(ofSize: 32)
        return headerLabel
    }()
    
    private let teamId: UITextField = {
        let teamId = UITextField()
        teamId.placeholder = "Enter TeamId to filter by"
        teamId.accessibilityIdentifier = "TeamIDTextField"
        teamId.keyboardType = .asciiCapable
        teamId.borderStyle = .roundedRect
        return teamId
    }()
    
    private let maxNumberOfSpaces: UITextField = {
        let maxNumberOfSpaces = UITextField()
        maxNumberOfSpaces.placeholder = "Max Spaces"
        maxNumberOfSpaces.accessibilityIdentifier = "MaxSpacesTextField"
        maxNumberOfSpaces.keyboardType = .numberPad
        maxNumberOfSpaces.borderStyle = .roundedRect
        return maxNumberOfSpaces
    }()
    
    private let spaceType: UITextField = {
        let spaceType = UITextField()
        spaceType.placeholder = "Space Type"
        spaceType.accessibilityIdentifier = "SpaceTypeTextField"
        spaceType.borderStyle = .roundedRect
        spaceType.tintColor = .clear
        return spaceType
    }()
    
    private let sortType: UITextField = {
        let sortType = UITextField()
        sortType.accessibilityIdentifier = "SpaceSortTypeTextField"
        sortType.placeholder = "Sort by"
        sortType.borderStyle = .roundedRect
        sortType.tintColor = .clear
        return sortType
    }()
    
    private let done: UIButton = {
        let done = UIButton()
        done.setTitle("Done", for: .normal)
        done.setTitleColor(.momentumBlue50, for: .normal)
        done.addTarget(self, action: #selector(onDoneTapped), for: .touchUpInside)
        return done
    }()
    
    private let clearFilters: UIButton = {
        let clearFilters = UIButton()
        clearFilters.setTitle("Clear Filters", for: .normal)
        clearFilters.setTitleColor(.momentumBlue50, for: .normal)
        clearFilters.addTarget(self, action: #selector(onClearFiltersTapped), for: .touchUpInside)
        return clearFilters
    }()
    
    private let segementedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["Space", "Read Status"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.accessibilityIdentifier = "FilteringSegmentedControl"
        return segmentedControl
    }()
    
    private lazy var filterStackView: UIStackView = {
        let filterStackView = UIStackView(arrangedSubviews: [teamId, maxNumberOfSpaces, sortType, spaceType, done, clearFilters, segementedControl, UIView()])
        filterStackView.translatesAutoresizingMaskIntoConstraints = false
        filterStackView.axis = .vertical
        filterStackView.spacing = 24
        filterStackView.distribution = .fill
        return filterStackView
    }()
    
    private let spaceTypePickerView = UIPickerView()
    private let spaceSortTypePickerView = UIPickerView()
    private let spaceSortTypes = [SpaceSortType.byId, SpaceSortType.byCreated, SpaceSortType.byLastActivity]
    private let spaceTypes = [SpaceType.direct, SpaceType.group]
    private var selectedSpaceType: SpaceType?
    private var selectedSpaceSortType: SpaceSortType?
    
    weak var delegate: FilterSpacesDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        configureView()
    }
}

extension FilterSpacesViewController {
    // MARK: Private Methods
    private func configureView() {
        constrainHeaderLabel()
        constrainFilterStackView()
        configureSortType()
        configureSpaceType()
    }
    
    private func constrainHeaderLabel() {
        view.addSubview(headerLabel)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: headerLabel, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 16),
            NSLayoutConstraint(item: headerLabel, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 16),
            NSLayoutConstraint(item: headerLabel, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 16)
        ])
    }
    
    private func constrainFilterStackView() {
        view.addSubview(filterStackView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: filterStackView, attribute: .leading, relatedBy: .equal, toItem: headerLabel, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: filterStackView, attribute: .top, relatedBy: .equal, toItem: headerLabel, attribute: .bottom, multiplier: 1, constant: 16),
            NSLayoutConstraint(item: filterStackView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: -16),
            NSLayoutConstraint(item: filterStackView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 16)
        ])
    }
    
    private func configureSortType() {
        spaceSortTypePickerView.delegate = self
        spaceSortTypePickerView.dataSource = self
        sortType.inputView = spaceSortTypePickerView
        sortType.inputAccessoryView = pickerViewToolBar(inputView: sortType)
    }
    
    private func configureSpaceType() {
        spaceTypePickerView.delegate = self
        spaceTypePickerView.dataSource = self
        spaceType.inputView = spaceTypePickerView
        spaceType.inputAccessoryView = pickerViewToolBar(inputView: spaceType)
    }
    
    private func pickerViewToolBar(inputView: UITextField) -> UIToolbar {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()

        let closeButton = UIBarButtonItem(title: "Close", style: UIBarButtonItem.Style.done, target: inputView, action: #selector(inputView.resignFirstResponder))

        toolBar.setItems([closeButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        return toolBar
    }
    
    @objc private func onDoneTapped() {
        delegate?.didUpdateListParameters(teamId: teamId.text, maxNumberOfSpaces: Int(maxNumberOfSpaces.text ?? "0"), spaceType: selectedSpaceType, sortType: selectedSpaceSortType, spaceValueType: segementedControl.selectedSegmentIndex == 0 ? .space : .readStatus)
        dismiss(animated: true)
    }
    
    @objc private func onClearFiltersTapped() {
        delegate?.didUpdateListParameters(teamId: nil, maxNumberOfSpaces: nil, spaceType: nil, sortType: nil, spaceValueType: .space)
        dismiss(animated: true)
    }
}

extension FilterSpacesViewController: UIPickerViewDataSource {
    // MARK: UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case spaceSortTypePickerView:
            return spaceSortTypes.count
        default:
            return spaceTypes.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case spaceSortTypePickerView:
            return spaceSortTypes[row].rawValue
        default:
            return spaceTypes[row].rawValue
        }
    }
}

extension FilterSpacesViewController: UIPickerViewDelegate {
    // MARK: UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case spaceSortTypePickerView:
            selectedSpaceSortType = spaceSortTypes[row]
            sortType.text = selectedSpaceSortType?.rawValue
        default:
            selectedSpaceType = spaceTypes[row]
            spaceType.text = selectedSpaceType?.rawValue
        }
    }
}
