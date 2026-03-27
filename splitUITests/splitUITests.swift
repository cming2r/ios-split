import XCTest

final class splitUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testScreenshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // 01 - 旅程列表（首頁）
        snapshot("01-TripList")

        // 02 - 掃描頁
        app.tabBars.buttons.element(boundBy: 1).tap()
        snapshot("02-Scanner")

        // 03 - 設定頁
        app.tabBars.buttons.element(boundBy: 2).tap()
        snapshot("03-Settings")
    }
}
