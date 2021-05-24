import XCTest

final class MessagingTeamsTests: XCTestCase, MessagingTestCase {
    func testTeamsViewControllerShowsEitherListOfTeamsOrNoTeamsLabel() {
        let app = launchAndNavigate(toTab: .teams)
        
        let table = app.tables.firstMatch
        let cell = table.cells.firstMatch
        waitForElementToAppear(cell)
        if cell.exists {
            XCTAssert(cell.staticTexts.firstMatch.exists, "The team cell should have an identifier stating the name of the team.")
            return
        }
        
        XCTAssert(app.staticTexts["No Teams"].exists, "If not teams returned from server we should notify user")
    }
    
    func testTeamsViewControllerAllowsUserToAddNewTeam() {
        let app = launchAndNavigate(toTab: .teams)
        let newSpaceName = String.random()
        
        app.navigationBars.matching(identifier: "Teams")
            .buttons.matching(identifier: "Add")
            .element
            .tap()
        
        let alert = app.alerts.matching(identifier: "Add Team")
        alert.textFields.firstMatch.typeText(newSpaceName)
        alert.buttons.matching(identifier: "Add").element.tap()
        
        let cell = app.tables.firstMatch.cells.staticTexts[newSpaceName]
        waitForElementToAppear(cell)
        
        XCTAssert(cell.exists, "We should be able to a new Team")
    }
    
    func testTeamCanBeFetchedByTeamId() {
        let app = launchAndNavigate(toTab: .teams)
        
        let firstTeam = app.tables.firstMatch.cells.firstMatch
        waitForElementToAppear(firstTeam)
        firstTeam.tap()
        
        let actionSheet = app.sheets["Team Actions"]
        waitForElementToAppear(actionSheet)
        actionSheet.buttons["Fetch Team by Id"].tap()
        
        let teamAlert = app.alerts["Team Found"]
        waitForElementToAppear(teamAlert)
        
        XCTAssert(teamAlert.staticTexts.containing(NSPredicate(labelContainsText: "Team Id:")).element.exists)
        XCTAssert(teamAlert.staticTexts.containing(NSPredicate(labelContainsText: "Created Date:")).element.exists)
    }
    
//    func testTeamNameCanBeUpdated() {
//        let app = launchAndNavigate(toTab: .teams)
//        let newSpaceName = String.random()
//
//        let firstTeam = app.tables.firstMatch.cells.firstMatch
//        waitForElementToAppear(firstTeam)
//        firstTeam.tap()
//        let actionSheet = app.sheets["Team Actions"]
//        waitForElementToAppear(actionSheet)
//        actionSheet.buttons["Update Team Name"].tap()
//        var alert = app.alerts.matching(identifier: "Update Team Name")
//        alert.textFields.firstMatch.typeText(newSpaceName)
//        alert.buttons.matching(identifier: "Update").element.tap()
//        alert = app.alerts.matching(identifier: "Success")
//        alert.buttons.matching(identifier: "Dismiss").element.tap()
//        let cell = app.tables.firstMatch.cells.staticTexts[newSpaceName]
//        waitForElementToAppear(cell)
//        XCTAssert(cell.exists, "Team's name should have been updated")
//    }
}
