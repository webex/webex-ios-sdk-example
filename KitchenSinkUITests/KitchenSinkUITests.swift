import XCTest

class KitchenSinkUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testApp() throws {
        firstWebexLogin()
        calling()
        webexLogout()
    }
    
    func firstWebexLogin() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Login"].tap()
        XCTAssert(app.staticTexts["Link to Webex"].exists)

        let testEmail = "xeiotulvlhijlxtrmw@awdrt.com"
        let testPassword = "Test1234"
        let webviewQuery = app.webViews
        let emailTestField = webviewQuery.textFields["Email address"]
        waitForElementToAppear(emailTestField)
        emailTestField.tap()
        emailTestField.typeText(testEmail)
        
        let nextButton = webviewQuery.buttons["Next"]
        nextButton.tap()
        
        let passwordTestField = app.secureTextFields.firstMatch
        waitForElementToAppear(passwordTestField)
        passwordTestField.tap()
        passwordTestField.typeText(testPassword)
        
        let signinButton = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Sign In")).firstMatch
        signinButton.tap()
        
        let homeVCTitle = app.navigationBars.staticTexts["Kitchen Sink"]
        waitForElementToAppear(homeVCTitle)
        XCTAssert(app.staticTexts["Kitchen Sink"].exists)
    }
    
    func calling() {
        outgoingCallWithDialpad()
        outgoingCallFromSearch()
        outgoingCallFromRecent()
        outgoingCallFromSpaces()
    }
    
    func outgoingCallWithDialpad() {
        let app = XCUIApplication()
        app.launch()
        
        let testEmail = "aksagarw@cisco.com"
        
        let collectionView = app.collectionViews.firstMatch
        let cell = collectionView.children(matching: .cell).matching(identifier: "Initiate Call").element
        cell.tap()
        
        let toggleButton = app.buttons["keyboardToggleButton"]
        toggleButton.tap()
        
        let inputField = app.textFields["callInput"]
        inputField.tap()
        inputField.typeText(testEmail)
        let dialButton = app.buttons["dialButton"]
        dialButton.tap()
        
        let endCallButton = app.buttons["endButton"]
        endCallButton.tap()
        XCTAssert(app.staticTexts["Call"].exists)
    }
    
    func outgoingCallFromSearch() {
        let app = XCUIApplication()
        app.launch()
        
        let testQuery = "Akshay Agarwal"
        
        let collectionView = app.collectionViews.firstMatch
        let cell = collectionView.children(matching: .cell).matching(identifier: "Initiate Call").element
        cell.tap()
        
        let segmentControl = app.otherElements.segmentedControls.matching(identifier: "initateCallSegmentControl").element
        segmentControl.buttons["Search"].tap()
        
        let searchField = app.searchFields["Type Email or Username"]
        searchField.tap()
        searchField.typeText(testQuery)
        
        let resultTable = app.tables.firstMatch
        let resultCell = resultTable.children(matching: .cell).element(boundBy: 0)
        waitForElementToAppear(resultCell)
        resultCell.buttons["actionButton"].tap()
        
        let endCallButton = app.buttons["endButton"]
        endCallButton.tap()
        XCTAssert(app.staticTexts["Search"].exists)
    }
    
    func outgoingCallFromRecent() {
        let app = XCUIApplication()
        app.launch()
                
        let collectionView = app.collectionViews.firstMatch
        let cell = collectionView.children(matching: .cell).matching(identifier: "Initiate Call").element
        cell.tap()
        
        let segmentControl = app.otherElements.segmentedControls.matching(identifier: "initateCallSegmentControl").element
        segmentControl.buttons["History"].tap()
        
        let resultTable = app.tables.firstMatch
        let resultCell = resultTable.children(matching: .cell).element(boundBy: 0)
        resultCell.buttons["actionButton"].tap()
        
        let endCallButton = app.buttons["endButton"]
        endCallButton.tap()
        XCTAssert(app.staticTexts["History"].exists)
    }
    
    func outgoingCallFromSpaces() {
        let app = XCUIApplication()
        app.launch()
                
        let collectionView = app.collectionViews.firstMatch
        let cell = collectionView.children(matching: .cell).matching(identifier: "Initiate Call").element
        cell.tap()
        
        let segmentControl = app.otherElements.segmentedControls.matching(identifier: "initateCallSegmentControl").element
        segmentControl.buttons["Spaces"].tap()
        
        let resultTable = app.tables.firstMatch
        let resultCell = resultTable.children(matching: .cell).element(boundBy: 0)
        resultCell.buttons["actionButton"].tap()
        
        let endCallButton = app.buttons["endButton"]
        endCallButton.tap()
        XCTAssert(app.staticTexts["Spaces"].exists)
    }
    
    func webexLogout() {
        let app = XCUIApplication()
        app.launch()
        
        let collectionView = app.collectionViews.firstMatch
        let cell = collectionView.children(matching: .cell).matching(identifier: "Logout").element
        cell.tap()
        
        let loginVCTitle = app.staticTexts["Link to Webex"]
        waitForElementToAppear(loginVCTitle)
        XCTAssert(loginVCTitle.exists)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
