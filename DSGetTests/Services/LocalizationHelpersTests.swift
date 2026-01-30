import XCTest
@testable import DSGet

final class LocalizationHelpersTests: XCTestCase {

    // MARK: - String Localization

    func testLocalizedWithSimpleKey() {
        let result = String.localized("general.ok")

        // Result should be non-empty; it returns the key itself if no translation exists
        XCTAssertFalse(result.isEmpty)
    }

    func testLocalizedReturnsKeyWhenNoTranslation() {
        let unknownKey = "this.key.does.not.exist.in.localization.files"
        let result = String.localized(unknownKey)

        // NSLocalizedString returns the key itself when no translation exists
        XCTAssertEqual(result, unknownKey)
    }

    func testLocalizedWithComment() {
        let result = String.localized("general.cancel", comment: "Cancel button title")

        XCTAssertFalse(result.isEmpty)
    }

    func testLocalizedWithArguments() {
        // Test with format arguments
        let result = String.localized("test.format", "Test comment", "Value1", 42)

        // Result should not be empty even if key doesn't exist
        XCTAssertFalse(result.isEmpty)
    }

    func testLocalizedWithSingleArgument() {
        let result = String.localized("test.single", "Single arg", "TestValue")

        XCTAssertFalse(result.isEmpty)
    }

    func testLocalizedWithNoArguments() {
        let result = String.localized("general.delete")

        XCTAssertFalse(result.isEmpty)
    }

    func testLocalizedWithIntegerArgument() {
        let result = String.localized("test.number", "", 123)

        XCTAssertFalse(result.isEmpty)
    }

    func testLocalizedWithDoubleArgument() {
        let result = String.localized("test.double", "", 45.67)

        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - EmptyStateText

    func testEmptyStateTextNoDownloadsTitleNotEmpty() {
        let result = String.localized(EmptyStateText.noDownloadsTitle)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextNoDownloadsDescriptionNotEmpty() {
        let result = String.localized(EmptyStateText.noDownloadsDescription)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextNoDownloadsActionNotEmpty() {
        let result = String.localized(EmptyStateText.noDownloadsAction)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextNoFeedsTitleNotEmpty() {
        let result = String.localized(EmptyStateText.noFeedsTitle)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextNoFeedsDescriptionNotEmpty() {
        let result = String.localized(EmptyStateText.noFeedsDescription)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextNoFeedsActionNotEmpty() {
        let result = String.localized(EmptyStateText.noFeedsAction)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextSearchPromptTitleNotEmpty() {
        let result = String.localized(EmptyStateText.searchPromptTitle)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextSearchPromptDescriptionNotEmpty() {
        let result = String.localized(EmptyStateText.searchPromptDescription)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextOfflineTitleNotEmpty() {
        let result = String.localized(EmptyStateText.offlineTitle)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextOfflineDescriptionNotEmpty() {
        let result = String.localized(EmptyStateText.offlineDescription)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextOfflineActionNotEmpty() {
        let result = String.localized(EmptyStateText.offlineAction)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextErrorTitleNotEmpty() {
        let result = String.localized(EmptyStateText.errorTitle)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextErrorActionNotEmpty() {
        let result = String.localized(EmptyStateText.errorAction)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextNotConnectedTitleNotEmpty() {
        let result = String.localized(EmptyStateText.notConnectedTitle)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextNotConnectedDescriptionNotEmpty() {
        let result = String.localized(EmptyStateText.notConnectedDescription)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextNotConnectedActionNotEmpty() {
        let result = String.localized(EmptyStateText.notConnectedAction)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextLoadingTitleNotEmpty() {
        let result = String.localized(EmptyStateText.loadingTitle)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextLoadingSubtitleNotEmpty() {
        let result = String.localized(EmptyStateText.loadingSubtitle)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextNoTasksTitleNotEmpty() {
        let result = String.localized(EmptyStateText.noTasksTitle)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextNoTasksDescriptionNotEmpty() {
        let result = String.localized(EmptyStateText.noTasksDescription)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyStateTextNoFoldersNotEmpty() {
        let result = String.localized(EmptyStateText.noFolders)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - ErrorText

    func testErrorTextTitleNotEmpty() {
        let result = String.localized(ErrorText.title)
        XCTAssertFalse(result.isEmpty)
    }

    func testErrorTextUnknownNotEmpty() {
        let result = String.localized(ErrorText.unknown)
        XCTAssertFalse(result.isEmpty)
    }

    func testErrorTextNetworkNotEmpty() {
        let result = String.localized(ErrorText.network)
        XCTAssertFalse(result.isEmpty)
    }

    func testErrorTextInvalidURLNotEmpty() {
        let result = String.localized(ErrorText.invalidURL)
        XCTAssertFalse(result.isEmpty)
    }

    func testErrorTextNoDownloadURLNotEmpty() {
        let result = String.localized(ErrorText.noDownloadURL)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - GeneralText

    func testGeneralTextOkNotEmpty() {
        let result = String.localized(GeneralText.ok)
        XCTAssertFalse(result.isEmpty)
    }

    func testGeneralTextCancelNotEmpty() {
        let result = String.localized(GeneralText.cancel)
        XCTAssertFalse(result.isEmpty)
    }

    func testGeneralTextDeleteNotEmpty() {
        let result = String.localized(GeneralText.delete)
        XCTAssertFalse(result.isEmpty)
    }

    func testGeneralTextCloseNotEmpty() {
        let result = String.localized(GeneralText.close)
        XCTAssertFalse(result.isEmpty)
    }

    func testGeneralTextCreateNotEmpty() {
        let result = String.localized(GeneralText.create)
        XCTAssertFalse(result.isEmpty)
    }

    func testGeneralTextCopyNotEmpty() {
        let result = String.localized(GeneralText.copy)
        XCTAssertFalse(result.isEmpty)
    }

    func testGeneralTextShareNotEmpty() {
        let result = String.localized(GeneralText.share)
        XCTAssertFalse(result.isEmpty)
    }

    func testGeneralTextSelectNotEmpty() {
        let result = String.localized(GeneralText.select)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - OfflineText

    func testOfflineTextModeNotEmpty() {
        let result = String.localized(OfflineText.mode)
        XCTAssertFalse(result.isEmpty)
    }

    func testOfflineTextCachedDataNotEmpty() {
        let result = String.localized(OfflineText.cachedData)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Key Constants

    func testEmptyStateTextKeysAreConstants() {
        // Verify that the constants are actual strings
        XCTAssertEqual(EmptyStateText.noDownloadsTitle, "empty.downloads.title")
        XCTAssertEqual(EmptyStateText.noFeedsTitle, "empty.feeds.title")
        XCTAssertEqual(EmptyStateText.offlineTitle, "empty.offline.title")
    }

    func testErrorTextKeysAreConstants() {
        XCTAssertEqual(ErrorText.title, "error.title")
        XCTAssertEqual(ErrorText.unknown, "error.unknown")
        XCTAssertEqual(ErrorText.network, "error.network")
    }

    func testGeneralTextKeysAreConstants() {
        XCTAssertEqual(GeneralText.ok, "general.ok")
        XCTAssertEqual(GeneralText.cancel, "general.cancel")
        XCTAssertEqual(GeneralText.delete, "general.delete")
    }

    func testOfflineTextKeysAreConstants() {
        XCTAssertEqual(OfflineText.mode, "offline.mode")
        XCTAssertEqual(OfflineText.cachedData, "offline.cachedData")
    }

    // MARK: - Integration Tests

    func testAllEmptyStateTextKeysReturnNonEmptyStrings() {
        let keys = [
            EmptyStateText.noDownloadsTitle,
            EmptyStateText.noDownloadsDescription,
            EmptyStateText.noDownloadsAction,
            EmptyStateText.noFeedsTitle,
            EmptyStateText.noFeedsDescription,
            EmptyStateText.noFeedsAction,
            EmptyStateText.searchPromptTitle,
            EmptyStateText.searchPromptDescription,
            EmptyStateText.offlineTitle,
            EmptyStateText.offlineDescription,
            EmptyStateText.offlineAction,
            EmptyStateText.errorTitle,
            EmptyStateText.errorAction,
            EmptyStateText.notConnectedTitle,
            EmptyStateText.notConnectedDescription,
            EmptyStateText.notConnectedAction,
            EmptyStateText.loadingTitle,
            EmptyStateText.loadingSubtitle,
            EmptyStateText.noTasksTitle,
            EmptyStateText.noTasksDescription,
            EmptyStateText.noFolders
        ]

        for key in keys {
            let localized = String.localized(key)
            XCTAssertFalse(localized.isEmpty, "Key \(key) returned empty string")
        }
    }

    func testAllErrorTextKeysReturnNonEmptyStrings() {
        let keys = [
            ErrorText.title,
            ErrorText.unknown,
            ErrorText.network,
            ErrorText.invalidURL,
            ErrorText.noDownloadURL
        ]

        for key in keys {
            let localized = String.localized(key)
            XCTAssertFalse(localized.isEmpty, "Key \(key) returned empty string")
        }
    }

    func testAllGeneralTextKeysReturnNonEmptyStrings() {
        let keys = [
            GeneralText.ok,
            GeneralText.cancel,
            GeneralText.delete,
            GeneralText.close,
            GeneralText.create,
            GeneralText.copy,
            GeneralText.share,
            GeneralText.select
        ]

        for key in keys {
            let localized = String.localized(key)
            XCTAssertFalse(localized.isEmpty, "Key \(key) returned empty string")
        }
    }

    func testAllOfflineTextKeysReturnNonEmptyStrings() {
        let keys = [
            OfflineText.mode,
            OfflineText.cachedData
        ]

        for key in keys {
            let localized = String.localized(key)
            XCTAssertFalse(localized.isEmpty, "Key \(key) returned empty string")
        }
    }
}
