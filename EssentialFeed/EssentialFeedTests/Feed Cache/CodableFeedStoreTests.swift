//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 16.06.2021.
//

import XCTest
import EssentialFeed

//- Insert
//    ✅ To empty cache works
//    - To non-empty cache overrides previous value
//    - Error (if possible to simulate, e.g., no write permission)
//
//- Retrieve
//    ✅ Empty cache works (before something is inserted)
//    ✅ Empty twice returns empty (no-side effects)
//    ✅ Non-empty cache returns data
//    ✅ Non-empty cache twice returns same data (retrieve should have no side-effects)
//    - Error (if possible to simulate, e.g., invalid data)
//
//- Delete
//    - Empty cache does nothing (cache stays empty and does not fail)
//    - Inserted data leaves cache empty
//    - Error (if possible to simulate, e.g., no write permission)
//
//- Side-effects must run serially to avoid race-conditions (deleting the wrong cache... overriding the latest data...)


class CodableFeedStore {
  private struct Cache: Codable {
    var feed: [CodableFeedImage]
    var timestamp: Date
    
    var localFeed: [LocalFeedImage] { feed.map { $0.local } }
  }
  
  private struct CodableFeedImage: Codable {
    private let id: UUID
    private let description: String?
    private let location: String?
    private let url: URL
    
    init(local: LocalFeedImage) {
      self.id = local.id
      self.description = local.description
      self.location = local.location
      self.url = local.url
    }
    
    var local: LocalFeedImage {
      LocalFeedImage(id: id, description: description, location: location, url: url)
    }
  }
  
  private let storeURL: URL
  
  init(storeURL: URL) {
    self.storeURL = storeURL
  }
  
  func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertCompletion) {
    let codableFeed = feed.map { CodableFeedImage(local: $0) }
    let cache = Cache(feed: codableFeed, timestamp: timestamp)
    let encoder = JSONEncoder()
    let data = try! encoder.encode(cache)
    try! data.write(to: storeURL)
    
    completion(nil)
  }
  
  func retrieve(completion: @escaping FeedStore.RetrieveCompletion) {
    guard let data = try? Data.init(contentsOf: storeURL) else {
      completion(.empty)
      return
    }
    let decoder = JSONDecoder()
    let cache = try! decoder.decode(Cache.self, from: data)
    completion(.found(cache.localFeed, cache.timestamp))
  }
}

class CodableFeedStoreTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    
    setupEmptyStoreState()
  }
  
  override func tearDown() {
    super.tearDown()
    
    undoStoreSideEffects()
  }
  
  func test_retrieve_deliversEmptyOnEmptyCache() {
    let sut = makeSUT()
    
    expect(sut, toRetrieve: .empty)
  }
  
  func test_retrieveTwice_deliversEmptyOnEmptyCache() {
    let sut = makeSUT()
    
    expect(sut, toRetrieveTwice: .empty)
  }

  func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
    let sut = makeSUT()
    let insertionFeed = uniqueFeedImages().local
    let insertionTimestamp = Date()
    
    insert((feed: insertionFeed, timestamp: insertionTimestamp), to: sut)
    
    expect(sut, toRetrieve: .found(insertionFeed, insertionTimestamp))
  }
  
  func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
    let sut = makeSUT()
    let insertionFeed = uniqueFeedImages().local
    let insertionTimestamp = Date()
    
    insert((feed: insertionFeed, timestamp: insertionTimestamp), to: sut)
    
    expect(sut, toRetrieveTwice: .found(insertionFeed, insertionTimestamp))
  }
 
  // MARK: - Helpers
  
  private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
    let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
  }
  
  private func testSpecificStoreURL() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
  }
  
  private func deleteStoreArtifacts() {
    try? FileManager.default.removeItem(at: testSpecificStoreURL())
  }
  
  private func setupEmptyStoreState() {
    deleteStoreArtifacts()
  }
  
  private func undoStoreSideEffects() {
    deleteStoreArtifacts()
  }
  
  private func insert(_ insertion: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) {
    let exp = expectation(description: "Wait until retrieve is completed")
    
    sut.insert(insertion.feed, timestamp: insertion.timestamp) { insertionError in
      XCTAssertNil(insertionError, "Expected to insert with no error")
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
  }
  
  private func expect(_ sut: CodableFeedStore, toRetrieveTwice expectedResult: RetrievalResult, file:StaticString = #filePath, line: UInt = #line) {
    expect(sut, toRetrieve: expectedResult, file: file, line: line)
    expect(sut, toRetrieve: expectedResult, file: file, line: line)
  }
  
  private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrievalResult, file:StaticString = #filePath, line: UInt = #line) {
    let exp = expectation(description: "Wait till retrieve completes")
    sut.retrieve { actualResult in
      switch (expectedResult, actualResult) {
      case (.empty, .empty):
        break
      case let (.failure(expectedError as NSError), .failure(actualError as NSError)):
        XCTAssertEqual(expectedError, actualError, file: file, line: line)
      case let (.found(expectedFeed, expectedTimestamp), .found(actualFeed, actualTimestamp)):
        XCTAssertEqual(expectedFeed, actualFeed, file: file, line: line)
        XCTAssertEqual(expectedTimestamp, actualTimestamp, file: file, line: line)
      default: XCTFail("Expected to restrieve \(expectedResult) result, got result: \(actualResult) instead", file: file, line: line)
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
  }

}
