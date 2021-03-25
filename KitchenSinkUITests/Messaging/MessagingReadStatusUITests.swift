import XCTest

class MessagingReadStatusUITests: XCTestCase, MessagingTestCase {
    func testSpacesViewControllerShowsListOfSpaceReadStatus() {
        let app = launchAndNavigate(toTab: .spaces)
        app.navigationBars.firstMatch.buttons["FilterSpaces"].tap()
        
        app.otherElements.segmentedControls
            .matching(identifier: "FilteringSegmentedControl").element
            .buttons["Read Status"]
            .tap()
        
        app.buttons["Done"].tap()
        let cell = app.tables.firstMatch.cells.firstMatch
        waitForElementToAppear(cell)
        if cell.exists {
            XCTAssertTrue(cell.staticTexts["Space Read Status"].exists, "Our space cell should have an identifier stating the name of the space.")
            return
        }
        XCTAssert(app.staticTexts["No Spaces"].exists, "If not spaces returned from server we should notify user")
    }
    
    func testSpacesViewControllerShowsListOfSpaceReadStatusLimitedByMaxNumber() {
        let maxNumber = Int.random(in: 1...100)
        let app = launchAndNavigate(toTab: .spaces)
        app.navigationBars.firstMatch.buttons["FilterSpaces"].tap()
        let textField = app.textFields["MaxSpacesTextField"]
        textField.tap()
        textField.typeText(String(maxNumber))
        
        app.otherElements.segmentedControls
            .matching(identifier: "FilteringSegmentedControl").element
            .buttons["Read Status"]
            .tap()
        
        app.buttons["Done"].tap()
        waitForElementToAppear(app.tables.firstMatch.cells.element)
        XCTAssert(app.tables.firstMatch.cells.count <= maxNumber)
    }
}
