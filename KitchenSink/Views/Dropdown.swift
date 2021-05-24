import Foundation
import UIKit
protocol MakeDropDownDataSourceProtocol {
    func getDataToDropDown(cell: UITableViewCell, indexPos: Int, makeDropDownIdentifier: String)
    func numberOfRows(makeDropDownIdentifier: String) -> Int
    
    //Optional Method for item selection
    func selectItemInDropDown(indexPos: Int, makeDropDownIdentifier: String)
}

extension MakeDropDownDataSourceProtocol {
    func selectItemInDropDown(indexPos: Int, makeDropDownIdentifier: String) {}
}

class MakeDropDown: UIView {
    // The DropDownIdentifier is to differentiate if you are using multiple Xibs
    var makeDropDownIdentifier: String = "DROP_DOWN"
    // Reuse Identifier of your custom cell
    var cellReusableIdentifier: String = "DROP_DOWN_CELL"
    // Table View
    var dropDownTableView: UITableView?
    var width: CGFloat = 0
    var offset: CGFloat = 0
    var makeDropDownDataSourceProtocol: MakeDropDownDataSourceProtocol?
    var nib: UINib? {
        didSet {
            dropDownTableView?.register(nib, forCellReuseIdentifier: self.cellReusableIdentifier)
        }
    }
    // Other Variables
    var viewPositionRef: CGRect?
    var isDropDownPresent: Bool = false
    
    // Make Table View Programatically
    
    func setUpDropDown(viewPositionReference: CGRect, offset: CGFloat) {
        self.addBorders()
        self.addShadowToView()
        self.frame = CGRect(x: viewPositionReference.minX, y: viewPositionReference.maxY + offset, width: 0, height: 0)
        dropDownTableView = UITableView(frame: CGRect(x: self.frame.minX, y: self.frame.minY, width: 0, height: 0))
        self.width = viewPositionReference.width
        self.offset = offset
        self.viewPositionRef = viewPositionReference
        dropDownTableView?.showsVerticalScrollIndicator = false
        dropDownTableView?.showsHorizontalScrollIndicator = false
        dropDownTableView?.backgroundColor = .white
        dropDownTableView?.separatorStyle = .none
        dropDownTableView?.delegate = self
        dropDownTableView?.dataSource = self
        dropDownTableView?.allowsSelection = true
        dropDownTableView?.isUserInteractionEnabled = true
        dropDownTableView?.tableFooterView = UIView()
        self.addSubview(dropDownTableView!)
    }
    
    // Shows Drop Down Menu
    func showDropDown(height: CGFloat) {
        if isDropDownPresent {
            self.hideDropDown()
        } else {
            isDropDownPresent = true
            self.frame = CGRect(x: (self.viewPositionRef?.minX)!, y: (self.viewPositionRef?.maxY)! + self.offset, width: width, height: 0)
            self.dropDownTableView?.frame = CGRect(x: 0, y: 0, width: width, height: 0)
            self.dropDownTableView?.reloadData()
            
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.05, options: .curveLinear, animations: {
                self.frame.size = CGSize(width: self.width, height: height)
                self.dropDownTableView?.frame.size = CGSize(width: self.width, height: height)
            })
        }
    }
    
    // Use this method if you want change height again and again
    // For eg in UISearchBar DropDownMenu
    func reloadDropDown(height: CGFloat) {
        self.frame = CGRect(x: (self.viewPositionRef?.minX)!, y: (self.viewPositionRef?.maxY)! + self.offset, width: width, height: 0)
        self.dropDownTableView?.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        self.dropDownTableView?.reloadData()
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.05, options: .curveLinear, animations: {
            self.frame.size = CGSize(width: self.width, height: height)
            self.dropDownTableView?.frame.size = CGSize(width: self.width, height: height)
        })
    }
    
    //Sets Row Height of your Custom XIB
    func setRowHeight(height: CGFloat) {
        self.dropDownTableView?.rowHeight = height
        self.dropDownTableView?.estimatedRowHeight = height
    }
    
    //Hides DropDownMenu
    func hideDropDown() {
        isDropDownPresent = false
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: .curveLinear, animations: {
            self.frame.size = CGSize(width: self.width, height: 0)
            self.dropDownTableView?.frame.size = CGSize(width: self.width, height: 0)
        })
    }
    
    // Removes DropDown Menu
    // Use it only if needed
    func removeDropDown() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: .curveLinear, animations: {
            self.dropDownTableView?.frame.size = CGSize(width: 0, height: 0)
        }) { _ in
            self.removeFromSuperview()
            self.dropDownTableView?.removeFromSuperview()
        }
    }
}

extension MakeDropDown: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (makeDropDownDataSourceProtocol?.numberOfRows(makeDropDownIdentifier: self.makeDropDownIdentifier) ?? 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = (dropDownTableView?.dequeueReusableCell(withIdentifier: self.cellReusableIdentifier) ?? UITableViewCell())
        makeDropDownDataSourceProtocol?.getDataToDropDown(cell: cell, indexPos: indexPath.row, makeDropDownIdentifier: self.makeDropDownIdentifier)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        makeDropDownDataSourceProtocol?.selectItemInDropDown(indexPos: indexPath.row, makeDropDownIdentifier: self.makeDropDownIdentifier)
    }
}

extension UIView {
    func addBorders(borderWidth: CGFloat = 0.2, borderColor: CGColor = UIColor.lightGray.cgColor) {
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor
    }
    
    func addShadowToView(shadowRadius: CGFloat = 2, alphaComponent: CGFloat = 0.6) {
        self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: alphaComponent).cgColor
        self.layer.shadowOffset = CGSize(width: -1, height: 2)
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowOpacity = 1
    }
}
