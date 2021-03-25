import XCTest

final class MessagingPeopleTests: XCTestCase, MessagingTestCase {
    func testPeopleCanBeListedForOrganizatoin() {
        let app = launchAndNavigate(toTab: .people)
        
        let firstSpace = app.tables.firstMatch.cells.firstMatch
        waitForElementToAppear(firstSpace)
        firstSpace.tap()
        
        let actionSheet = app.sheets["People Actions"]
        waitForElementToAppear(actionSheet)
        actionSheet.buttons["Show People"].tap()
        
        let table = app.tables["PeopleDetailsTableView"]
        waitForElementToAppear(table)
        
        let cell = table.cells.firstMatch
        waitForElementToAppear(cell)
        
        XCTAssert(cell.staticTexts.containing(NSPredicate(labelContainsText: "Display Name:")).element.exists)
        XCTAssert(cell.staticTexts.containing(NSPredicate(labelContainsText: "Email:")).element.exists)
    }
}
