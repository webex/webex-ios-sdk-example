import XCTest

protocol MessagingTestCase: XCTestCase {
    func launchAndNavigate(toTab tab: MessagingTab) -> XCUIApplication
    func switchTo(tab: MessagingTab, in application: XCUIApplication)
}

extension MessagingTestCase {
    func login() -> XCUIApplication {
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
        
        return app
    }
    
    func launchAndNavigate(toTab tab: MessagingTab) -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        
        if !app.staticTexts["Kitchen Sink"].exists {
            _ = login()
        }
        
        app.collectionViews.firstMatch
            .children(matching: .cell)
            .matching(identifier: KitchenSinkFeature.messaging.rawValue)
            .element
            .tap()
        
        switchTo(tab: tab, in: app)
        return app
    }
    
    func switchTo(tab: MessagingTab, in application: XCUIApplication) {
        application.otherElements.segmentedControls
            .matching(identifier: "MessagingSegmentedControl").element
            .buttons[tab.rawValue]
            .tap()
    }
}
