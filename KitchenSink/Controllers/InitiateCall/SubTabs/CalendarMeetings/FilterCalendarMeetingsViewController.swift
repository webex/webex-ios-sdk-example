import UIKit
import WebexSDK

protocol FilterCalendarMeetingsDelegate: AnyObject {
    func didUpdateListParameters(startDate: Date?, endDate: Date?)
}

final class FilterCalendarMeetingsViewController: UIViewController {
    private let headerLabel: UILabel = {
        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = "Filter Calendar Meetings"
        headerLabel.font = .boldSystemFont(ofSize: 32)
        return headerLabel
    }()
    
    private var startDateLabel: UILabel = {
        let label = UILabel()
        label.text = "Start Date"
        return label
    }()
    
    var startDatePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.locale = .current
        // Minimum of 7 days prior to current date
        dp.minimumDate = Date(timeIntervalSinceNow: -7 * 24 * 60 * 60)
        if #available(iOS 13.4, *) {
            dp.preferredDatePickerStyle = .compact
        }
        dp.addTarget(self, action: #selector(onStartDateChanged(_:)), for: .valueChanged)
        return dp
    }()
    
    private var endDateLabel: UILabel = {
        let label = UILabel()
        label.text = "End Date"
        return label
    }()
    
    var endDatePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.locale = .current
        // Maximum of 30 days from to current date
        dp.maximumDate = Date(timeIntervalSinceNow: 30 * 24 * 60 * 60)
        if #available(iOS 13.4, *) {
            dp.preferredDatePickerStyle = .compact
        }
        dp.addTarget(self, action: #selector(onEndDateChanged(_:)), for: .valueChanged)
        return dp
    }()
    
    @objc func onStartDateChanged(_ sender: UIDatePicker) {
        self.endDatePicker.minimumDate = sender.date
        closeDatePickerAfterSelection(picker: endDatePicker)
    }
    
    @objc func onEndDateChanged(_ sender: UIDatePicker) {
        self.startDatePicker.maximumDate = sender.date
        closeDatePickerAfterSelection(picker: startDatePicker)
    }
    
    private func closeDatePickerAfterSelection(picker: UIDatePicker) {
        if #available(iOS 13.4, *) {
            presentedViewController?.dismiss(animated: true, completion: nil)
        }
        picker.resignFirstResponder()
    }
    
    private let done: UIButton = {
        let done = UIButton()
        done.setTitle("Done", for: .normal)
        done.setTitleColor(.white, for: .normal)
        done.backgroundColor = .momentumBlue50
        done.layer.cornerRadius = 10
        done.addTarget(self, action: #selector(onDoneTapped), for: .touchUpInside)
        return done
    }()
    
    private let clearFilters: UIButton = {
        let clearFilters = UIButton()
        clearFilters.setTitle("Clear Filters", for: .normal)
        clearFilters.setTitleColor(.white, for: .normal)
        clearFilters.backgroundColor = .momentumRed50
        clearFilters.layer.cornerRadius = 10
        clearFilters.addTarget(self, action: #selector(onClearFiltersTapped), for: .touchUpInside)
        return clearFilters
    }()
    
    private lazy var filterStackView: UIStackView = {
        let filterStackView = UIStackView(arrangedSubviews: [startDateLabel, startDatePicker, endDateLabel, endDatePicker, done, clearFilters, UIView()])
        filterStackView.translatesAutoresizingMaskIntoConstraints = false
        filterStackView.axis = .vertical
        filterStackView.spacing = 24
        filterStackView.distribution = .fill
        return filterStackView
    }()
    
    weak var delegate: FilterCalendarMeetingsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startDatePicker.maximumDate = endDatePicker.date
        self.endDatePicker.minimumDate = startDatePicker.date
    }
}

extension FilterCalendarMeetingsViewController {
    // MARK: Private Methods
    private func configureView() {
        constrainHeaderLabel()
        constrainFilterStackView()
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
            NSLayoutConstraint(item: filterStackView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: -16)
        ])
    }
    
    @objc private func onDoneTapped() {
        delegate?.didUpdateListParameters(startDate: startDatePicker.date, endDate: endDatePicker.date)
        dismiss(animated: true)
    }
    
    @objc private func onClearFiltersTapped() {
        delegate?.didUpdateListParameters(startDate: nil, endDate: nil)
        dismiss(animated: true)
    }
}
