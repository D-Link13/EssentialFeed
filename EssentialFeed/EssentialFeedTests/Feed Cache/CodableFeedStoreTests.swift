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
//    - Empty twice returns empty (no-side effects)
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
  func retrieve(completion: @escaping FeedStore.RetrieveCompletion) {
    completion(.empty)
  }
}

class CodableFeedStoreTests: XCTestCase {
  
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

}
