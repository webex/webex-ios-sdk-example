import XCTest

final class MessagingTests: XCTestCase, MessagingTestCase {
    func testSpacesViewControllerShouldAllowUserToSendAMessageToASpaceWithConfirmation() {
        let app = launchAndNavigate(toTab: .spaces)
        let expectedText = "KitchenSink UI Test"
        
        let firstSpace = app.tables.firstMatch.cells.firstMatch
        waitForElementToAppear(firstSpace)
        firstSpace.tap()
        
        let actionSheet = app.sheets["Space Actions"]
        waitForElementToAppear(actionSheet)
        actionSheet.buttons["Send Message"].tap()
        
        let messageAlert = app.alerts["Send Message"]
        waitForElementToAppear(messageAlert)
        messageAlert.typeText(expectedText)
        messageAlert.buttons["Send"].tap()
        
        let confirmationAlert = app.alerts["New Message Arrived"]
        waitForElementToAppear(confirmationAlert)
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", expectedText)
        XCTAssert(confirmationAlert.staticTexts.containing(predicate).element.exists)
    }
}
