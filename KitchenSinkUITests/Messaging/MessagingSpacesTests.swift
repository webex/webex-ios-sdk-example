import XCTest

final class MessagingSpacesTests: XCTestCase, MessagingTestCase {
    func testSpacesViewControllerShowsEitherListOfSpacesOrNoSpacesLabel() {
        let app = launchAndNavigate(toTab: .spaces)
        
        let table = app.tables.firstMatch
        let cell = table.cells.firstMatch
        waitForElementToAppear(cell)
        if cell.exists {
            XCTAssert(cell.staticTexts.firstMatch.exists, "Our space cell should have an identifier stating the name of the space.")
            return
        }
        
        XCTAssert(app.staticTexts["No Spaces"].exists, "If not spaces returned from server we should notify user")
    }
    
    func testSpacesViewControllerAllowsUserToAddNewSpace() {
        let app = launchAndNavigate(toTab: .spaces)
        let newSpaceName = String.random()
        
        app.navigationBars.matching(identifier: "Spaces")
            .buttons.matching(identifier: "Add")
            .element
            .tap()
        
        let alert = app.alerts.matching(identifier: "Add Space")
        alert.textFields.firstMatch.typeText(newSpaceName)
        alert.buttons.matching(identifier: "Add").element.tap()
        
        let cell = app.tables.firstMatch.cells.staticTexts[newSpaceName]
        waitForElementToAppear(cell)
        
        XCTAssert(cell.exists, "We should be able to a new space")
    }
    
    func testTeamsViewControllerShouldAllowUserToAddASpaceToATeam() {
        let app = launchAndNavigate(toTab: .teams)
        let newSpaceName = String.random()
        
        let teamCell = app.tables.firstMatch.cells.firstMatch
        waitForElementToAppear(teamCell)
        teamCell.tap()
        
        app.sheets.matching(identifier: "Team Actions")
            .buttons.matching(identifier: "Add Space to Team")
            .element
            .tap()
        
        let alert = app.alerts.matching(identifier: "Add Space")
        alert.textFields.firstMatch.typeText(newSpaceName)
        alert.buttons.matching(identifier: "Add").element.tap()
        
        switchTo(tab: .spaces, in: app)
        
        let spaceCell = app.tables.firstMatch.cells.staticTexts[newSpaceName]
        waitForElementToAppear(spaceCell)
        XCTAssert(spaceCell.exists, "We should be able to a new space")
    }
    
    func testSpacesCanBeFilteredByTeamId() {
        let teamId = "7f584570-c548-11ea-a151-17a19ac10f97"
        let app = launchAndNavigate(toTab: .spaces)
        app.navigationBars.firstMatch.buttons["FilterSpaces"].tap()
        let textField = app.textFields["TeamIDTextField"]
        textField.tap()
        textField.typeText(teamId)
        app.buttons["Done"].tap()
        waitForElementToAppear(app.tables.firstMatch.cells.element)
        let predicate = NSPredicate(labelContainsText: teamId)
        XCTAssert(app.tables.firstMatch.cells.staticTexts.matching(predicate).count == app.tables.firstMatch.cells.count)
    }
    
    func testSpacesCanBeLimitedByMaxNumber() {
        let expected = Int.random(in: 1...10)
        let app = launchAndNavigate(toTab: .spaces)
        app.navigationBars.firstMatch.buttons["FilterSpaces"].tap()
        let textField = app.textFields["MaxSpacesTextField"]
        textField.tap()
        textField.typeText(String(expected))
        app.buttons["Done"].tap()
        waitForElementToAppear(app.tables.firstMatch.cells.element)
        XCTAssert(app.tables.firstMatch.cells.count <= expected)
    }
    
    func testSpacesCanBeFilteredBySpaceType() {
        let expected = "group"
        let app = launchAndNavigate(toTab: .spaces)
        app.navigationBars.firstMatch.buttons["FilterSpaces"].tap()
        let textField = app.textFields["SpaceTypeTextField"]
        textField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: expected)
        app.buttons["Done"].tap()
        XCTAssert(app.tables.firstMatch.cells.staticTexts.matching(NSPredicate(labelContainsText: expected)).count == app.tables.firstMatch.cells.count)
    }
    
    func testSpacesCanBeSortedBySpaceId() {
        let expected = "id"
        let descriptor = "Space Id: "
        let app = launchAndNavigate(toTab: .spaces)
        app.navigationBars.firstMatch.buttons["FilterSpaces"].tap()
        let textField = app.textFields["SpaceSortTypeTextField"]
        textField.tap()
        app.pickerWheels.firstMatch.swipeUp()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: expected)
        app.buttons["Done"].tap()
        
        let spaceIds = app.tables.firstMatch.cells.staticTexts.matching(NSPredicate(labelContainsText: descriptor)).allElementsBoundByAccessibilityElement.map { element -> String in
            guard let firstLine = element.label.split(whereSeparator: { $0 == "," }).first else { return element.label }
            return firstLine.replacingOccurrences(of: descriptor, with: "")
        }
        
        XCTAssert(spaceIds.isAscending())
    }
    
    func testSpacesCanBeSortedBySpaceCreated() {
        let expected = "created"
        let descriptor = "Created Date: "
        let indexOfRelevantValue = 3
        
        let app = launchAndNavigate(toTab: .spaces)
        app.navigationBars.firstMatch.buttons["FilterSpaces"].tap()
        let textField = app.textFields["SpaceSortTypeTextField"]
        textField.tap()
        app.pickerWheels.firstMatch.swipeUp()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: expected)
        app.buttons["Done"].tap()
        
        let createdDates = app.tables.firstMatch.cells.staticTexts.matching(NSPredicate(labelContainsText: descriptor)).allElementsBoundByAccessibilityElement.map { element -> String in
            guard let fourthLine = element.label.split(whereSeparator: { $0 == "," }).element(at: indexOfRelevantValue) else { return element.label }
            return fourthLine.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: descriptor, with: "")
        }
        
        XCTAssert(createdDates.isAscending())
    }
    
    func testSpacesCanBeSortedBySpaceLastActivity() {
        let expected = "lastactivity"
        let descriptor = "Last Activity: "
        let indexOfRelevantValue = 4
        
        let app = launchAndNavigate(toTab: .spaces)
        app.navigationBars.firstMatch.buttons["FilterSpaces"].tap()
        let textField = app.textFields["SpaceSortTypeTextField"]
        textField.tap()
        app.pickerWheels.firstMatch.swipeUp()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: expected)
        app.buttons["Done"].tap()
        
        let lastActivityDates = app.tables.firstMatch.cells.staticTexts.matching(NSPredicate(labelContainsText: descriptor)).allElementsBoundByAccessibilityElement.map { element -> String in
            guard let fourthLine = element.label.split(whereSeparator: { $0 == "," }).element(at: indexOfRelevantValue) else { return element.label }
            return fourthLine.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: descriptor, with: "")
        }
        
        XCTAssert(lastActivityDates.isAscending())
    }
    
    func testSpaceCanBeFetchedBySpaceId() {
        let app = launchAndNavigate(toTab: .spaces)
        
        let firstSpace = app.tables.firstMatch.cells.firstMatch
        waitForElementToAppear(firstSpace)
        firstSpace.tap()
        
        let actionSheet = app.sheets["Space Actions"]
        waitForElementToAppear(actionSheet)
        actionSheet.buttons["Fetch Space by Id"].tap()
        
        let spaceAlert = app.alerts["Space Found"]
        waitForElementToAppear(spaceAlert)
        
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Space Id:")).element.exists)
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Space Type:")).element.exists)
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Created Date:")).element.exists)
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Last Activity:")).element.exists)
    }
    
    func testSpaceReadStatusCanBeFetchedBySpaceId() {
        let app = launchAndNavigate(toTab: .spaces)

        let firstSpace = app.tables.firstMatch.cells.firstMatch
        waitForElementToAppear(firstSpace)
        firstSpace.tap()
      
        let actionSheet = app.sheets["Space Actions"]
        waitForElementToAppear(actionSheet)
        actionSheet.buttons["Fetch Space Read Status"].tap()
        
        let spaceAlert = app.alerts["Space Read Status"]
        waitForElementToAppear(spaceAlert)
        
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Space Id:")).element.exists)
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Space Type:")).element.exists)
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Last Activity:")).element.exists)
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Last Seen Activity:")).element.exists)
    }

    func testMembersCanBeListedForASpace() {
        let app = launchAndNavigate(toTab: .spaces)
        
        let firstSpace = app.tables.firstMatch.cells.firstMatch
        waitForElementToAppear(firstSpace)
        firstSpace.tap()
        
        let actionSheet = app.sheets["Space Actions"]
        waitForElementToAppear(actionSheet)
        actionSheet.buttons["Show Space Members"].tap()
        
        let table = app.tables["SpaceMembershipTableView"]
        waitForElementToAppear(table)
        
        let cell = table.cells.firstMatch
        waitForElementToAppear(cell)
        
        XCTAssert(cell.staticTexts.containing(NSPredicate(labelContainsText: "Display Name:")).element.exists)
        XCTAssert(cell.staticTexts.containing(NSPredicate(labelContainsText: "Email:")).element.exists)
    }
    
    func testMessagesCanBeListedForASpace() {
        let app = launchAndNavigate(toTab: .spaces)
        
        let firstSpace = app.tables.firstMatch.cells.firstMatch
        waitForElementToAppear(firstSpace)
        firstSpace.tap()
        
        let actionSheet = app.sheets["Space Actions"]
        waitForElementToAppear(actionSheet)
        actionSheet.buttons["Show Messages in Space"].tap()
        
        let table = app.tables["SpaceMessagesTableView"]
        waitForElementToAppear(table)
        
        let cell = table.cells.firstMatch
        waitForElementToAppear(cell)
        
        XCTAssert(cell.staticTexts.containing(NSPredicate(labelContainsText: "Sender:")).element.exists)
    }
    
    func testMeetingInfoCanBeListedForASpace() {
        let app = launchAndNavigate(toTab: .spaces)
        
        let firstSpace = app.tables.firstMatch.cells.firstMatch
        waitForElementToAppear(firstSpace)
        firstSpace.tap()
        
        let actionSheet = app.sheets["Space Actions"]
        waitForElementToAppear(actionSheet)
        actionSheet.buttons["Get Space Meeting Info"].tap()
        
        let spaceAlert = app.alerts["Meeting Information"]
        waitForElementToAppear(spaceAlert)
        
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Space Id:")).element.exists)
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Meeting Link:")).element.exists)
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Sip Address:")).element.exists)
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Meeting Number:")).element.exists)
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Call In Toll Free Number:")).element.exists)
        XCTAssert(spaceAlert.staticTexts.containing(NSPredicate(labelContainsText: "Call In Toll Number:")).element.exists)
    }
}
