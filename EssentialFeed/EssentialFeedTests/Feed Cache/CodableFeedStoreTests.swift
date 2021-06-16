//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 16.06.2021.
//

import XCTest
import EssentialFeed

//- Insert
//    - To empty cache works
//    - To non-empty cache overrides previous value
//    - Error (if possible to simulate, e.g., no write permission)
//
//- Retrieve
//    ✅ Empty cache works (before something is inserted)
//    ✅ Empty twice returns empty (no-side effects)
//    - Non-empty cache returns data
//    - Non-empty cache twice returns same data (retrieve should have no side-effects)
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
    var feed: [LocalFeedImage]
    var timestamp: Date
  }
  
  private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
  
  func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertCompletion) {
    let cache = Cache(feed: feed, timestamp: timestamp)
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
    completion(.found(cache.feed, cache.timestamp))
  }
}

class CodableFeedStoreTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
    try? FileManager.default.removeItem(at: storeURL)
  }
  
  override func tearDown() {
    super.tearDown()
    let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
    try? FileManager.default.removeItem(at: storeURL)
  }
  
  func test_retrieve_deliversEmptyOnEmptyCache() {
    let sut = CodableFeedStore()
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
    let sut = CodableFeedStore()
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
    let sut = CodableFeedStore()
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
  
}
