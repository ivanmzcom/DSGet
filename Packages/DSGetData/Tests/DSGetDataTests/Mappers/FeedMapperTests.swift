import XCTest
@testable import DSGetData
@testable import DSGetDomain

final class FeedMapperTests: XCTestCase {

    var mapper: FeedMapper!

    override func setUp() {
        mapper = FeedMapper()
    }

    // MARK: - Feed Mapping Tests

    func testMapToEntityBasic() {
        // Given
        let dto = RSSFeedDTO(
            id: .int(123),
            title: "Test Feed",
            url: "https://example.com/feed.rss",
            isUpdating: false,
            lastUpdate: Date().timeIntervalSince1970
        )

        // When
        let entity = mapper.mapToEntity(dto)

        // Then
        XCTAssertEqual(entity.id.rawValue, "123")
        XCTAssertEqual(entity.title, "Test Feed")
        XCTAssertEqual(entity.url?.absoluteString, "https://example.com/feed.rss")
        XCTAssertFalse(entity.isUpdating)
        XCTAssertNotNil(entity.lastUpdate)
    }

    func testMapToEntityWithStringID() {
        // Given
        let dto = RSSFeedDTO(
            id: .string("feed-abc"),
            title: "String ID Feed",
            url: nil,
            isUpdating: true,
            lastUpdate: nil
        )

        // When
        let entity = mapper.mapToEntity(dto)

        // Then
        XCTAssertEqual(entity.id.rawValue, "feed-abc")
        XCTAssertNil(entity.url)
        XCTAssertTrue(entity.isUpdating)
        XCTAssertNil(entity.lastUpdate)
    }

    func testMapToEntities() {
        // Given
        let dtos = [
            RSSFeedDTO(id: .int(1), title: "Feed 1", url: nil, isUpdating: false, lastUpdate: nil),
            RSSFeedDTO(id: .int(2), title: "Feed 2", url: nil, isUpdating: false, lastUpdate: nil),
            RSSFeedDTO(id: .int(3), title: "Feed 3", url: nil, isUpdating: false, lastUpdate: nil)
        ]

        // When
        let entities = mapper.mapToEntities(dtos)

        // Then
        XCTAssertEqual(entities.count, 3)
        XCTAssertEqual(entities[0].title, "Feed 1")
        XCTAssertEqual(entities[1].title, "Feed 2")
        XCTAssertEqual(entities[2].title, "Feed 3")
    }

    // MARK: - Feed Item Mapping Tests

    func testMapItemToEntity() {
        // Given
        let dto = RSSFeedItemDTO(
            id: "item-123",
            title: "Test Item",
            link: "https://example.com/item",
            externalLink: "https://example.com/external",
            downloadUri: "magnet:?xt=test",
            size: "1024000",
            time: Date().timeIntervalSince1970,
            isNew: true,
            enclosure: nil
        )

        // When
        let entity = mapper.mapItemToEntity(dto)

        // Then
        XCTAssertEqual(entity.id.rawValue, "item-123")
        XCTAssertEqual(entity.title, "Test Item")
        XCTAssertEqual(entity.downloadURL?.absoluteString, "magnet:?xt=test")
        XCTAssertEqual(entity.externalURL?.absoluteString, "https://example.com/external")
        XCTAssertTrue(entity.isNew)
    }

    func testMapItemToEntityWithEnclosure() {
        // Given
        let dto = RSSFeedItemDTO(
            id: "item-456",
            title: "Item with Enclosure",
            link: nil,
            externalLink: nil,
            downloadUri: nil,
            size: nil,
            time: nil,
            isNew: false,
            enclosure: RSSFeedItemEnclosureDTO(url: "https://example.com/download.torrent")
        )

        // When
        let entity = mapper.mapItemToEntity(dto)

        // Then
        XCTAssertEqual(entity.downloadURL?.absoluteString, "https://example.com/download.torrent")
    }

    func testMapItemsToEntities() {
        // Given
        let dtos = [
            RSSFeedItemDTO(id: "1", title: "Item 1", link: nil, externalLink: nil, downloadUri: "url1", size: nil, time: nil, isNew: true, enclosure: nil),
            RSSFeedItemDTO(id: "2", title: "Item 2", link: nil, externalLink: nil, downloadUri: "url2", size: nil, time: nil, isNew: false, enclosure: nil)
        ]

        // When
        let entities = mapper.mapItemsToEntities(dtos)

        // Then
        XCTAssertEqual(entities.count, 2)
        XCTAssertEqual(entities[0].title, "Item 1")
        XCTAssertEqual(entities[1].title, "Item 2")
    }
}
