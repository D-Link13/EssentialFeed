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
    let exp = expectation(description: "Wait until retrieve is completed")
    
    sut.retrieve { result in
      switch result {
      case .empty: break
      default: XCTFail("Expected empty, got result: \(result)")
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
  }
  
  func test_retrieveTwice_deliversEmptyOnEmptyCache() {
    let sut = makeSUT()
    let exp = expectation(description: "Wait until retrieve is completed")
    
    sut.retrieve { firstResult in
      sut.retrieve { secondResult in
        switch (firstResult, secondResult) {
        case (.empty, .empty): break
        default: XCTFail("Expected empty twice, got firstResult: \(firstResult), secondResult: \(secondResult)")
        }
        exp.fulfill()
      }
    }
    wait(for: [exp], timeout: 1.0)
  }

  func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
    let sut = makeSUT()
    let insertionFeed = uniqueFeedImages().local
    let insertionTimestamp = Date()
    let exp = expectation(description: "Wait until retrieve is completed")
    
    sut.insert(insertionFeed, timestamp: insertionTimestamp) { insertionError in
      XCTAssertNil(insertionError, "Expected to insert with no error")
      sut.retrieve { retrievedResult in
        switch retrievedResult {
        case let .found(retrievedFeed, retrievedTimestamp):
          XCTAssertEqual(insertionFeed, retrievedFeed)
          XCTAssertEqual(insertionTimestamp, retrievedTimestamp)
        default:
          XCTFail("Expected found result, got result: \(retrievedResult)")
        }
        exp.fulfill()
      }
    }
    wait(for: [exp], timeout: 1.0)
  }
  
  func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
    let sut = makeSUT()
    let insertionFeed = uniqueFeedImages().local
    let insertionTimestamp = Date()
    let exp = expectation(description: "Wait until retrieve is completed")
    
    sut.insert(insertionFeed, timestamp: insertionTimestamp) { insertionError in
      XCTAssertNil(insertionError, "Expected to insert with no error")
      sut.retrieve { firstRetrievedResult in
        sut.retrieve { secondRetrievedResult in
          switch (firstRetrievedResult, secondRetrievedResult) {
          case let (.found(firstRetrievedFeed, firstRetrievedTimestamp), .found(secondRetrievedFeed, secondRetrievedTimestamp)) :
            XCTAssertEqual(firstRetrievedFeed, secondRetrievedFeed)
            XCTAssertEqual(firstRetrievedTimestamp, secondRetrievedTimestamp)
          default:
            XCTFail("Expected equal .found results, got result: \((firstRetrievedResult, secondRetrievedResult))")
          }
          exp.fulfill()
        }
      }
    }
    wait(for: [exp], timeout: 1.0)
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
  
}
