import XCTest

class RunnerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Screenshot Tests

    func testTakeScreenshots() {
        // Wait for app to fully load
        sleep(2)

        // Screenshot 1: Main timeslot view with today's tracking
        snapshot("01-MainView")

        // Wait for any animations to complete
        sleep(1)

        // Screenshot 2: Scroll down to show more timeslots
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
            snapshot("02-TimeslotList")
        }

        // Screenshot 3: Try to access settings (look for settings icon/button)
        // Note: Adjust selector based on your actual app structure
        let settingsButton = app.buttons["Settings"].firstMatch
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            sleep(1)
            snapshot("03-Settings")

            // Go back to main view
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                sleep(1)
            }
        }

        // Screenshot 4: Try to access analysis/heatmap view
        // Note: Adjust selector based on your actual app structure
        let analysisButton = app.buttons["Analysis"].firstMatch
        if analysisButton.waitForExistence(timeout: 5) {
            analysisButton.tap()
            sleep(1)
            snapshot("04-Analysis")
        }

        // Add more screenshots as needed for other screens
    }
}
