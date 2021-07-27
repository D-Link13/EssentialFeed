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
//    ✅ To non-empty cache overrides previous value
//    ✅ Error (if possible to simulate, e.g., no write permission)
//
//- Retrieve
//    ✅ Empty cache works (before something is inserted)
//    ✅ Empty twice returns empty (no-side effects)
//    ✅ Non-empty cache returns data
//    ✅ Non-empty cache twice returns same data (retrieve should have no side-effects)
//    ✅ Error (if possible to simulate, e.g., invalid data)
//
//- Delete
//    ✅ Empty cache does nothing (cache stays empty and does not fail)
//    ✅ Inserted data leaves cache empty
//    ✅ Error (if possible to simulate, e.g., no write permission)
//
//✅ Side-effects must run serially to avoid race-conditions (deleting the wrong cache... overriding the latest data...)

class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
  
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

  func test_retrieve_deliversFoundValuesAfterInsertion() {
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
  
  func test_retrieve_deliversFailureOnRetrieveError() {
    let storeURL = testSpecificStoreURL()
    let sut = makeSUT(storeURL: storeURL)
    
    try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
    
    expect(sut, toRetrieve: .failure(anyNSError()))
  }
  
  func test_retrieve_hasNoSideEffectsOnRetrieveError() {
    let storeURL = testSpecificStoreURL()
    let sut = makeSUT(storeURL: storeURL)
    
    try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
    
    expect(sut, toRetrieveTwice: .failure(anyNSError()))
  }
  
  func test_retrieve_runsAsyncronously() {
    let sut = makeSUT()
    var completedOperations = [XCTestExpectation]()
    let exp = expectation(description: "Wait until retrieve completes")

    sut.retrieve { _ in
      completedOperations.append(exp)
      exp.fulfill()
    }

    XCTAssertEqual(completedOperations.count, 0, "Expected retrieve not to block further code execution (asyncronous)")
    wait(for: [exp], timeout: 3.0)
    XCTAssertEqual(completedOperations, [exp], "Expected retrieve to complete after timeout")
  }
  
  
  func test_insert_deliversNoErrorOnEmptyCache() {
    let sut = makeSUT()
    
    let insertionError = insert((uniqueFeedImages().local, Date()), to: sut)
    
    XCTAssertNil(insertionError, "Expected to insert cache successfully")
  }
  
  func test_insert_deliversNoErrorOnNonEmptyCache() {
    let sut = makeSUT()
    insert((uniqueFeedImages().local, Date()), to: sut)
    
    let insertionError = insert((uniqueFeedImages().local, Date()), to: sut)
    
    XCTAssertNil(insertionError, "Expected to override cache successfully")
  }
  
  func test_insert_overridesPreviousInsertedCachedData() {
    let sut = makeSUT()
    
    let firstInsertionError = insert((feed: uniqueFeedImages().local, timestamp: Date()), to: sut)
    XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")
    
    let latestFeed = uniqueFeedImages().local
    let latestTimestamp = Date()
    
    let latestInsertionError = insert((feed: latestFeed, timestamp: latestTimestamp), to: sut)
    XCTAssertNil(latestInsertionError, "Expected to override cache successfully")
    
    expect(sut, toRetrieve: .found(latestFeed, latestTimestamp))
  }
  
  func test_insert_runAsyncronously() {
    let sut = makeSUT()
    var completedOperations = [XCTestExpectation]()

    let exp = expectation(description: "Wait until insert completes")
    sut.insert(uniqueFeedImages().local, timestamp: Date()) { _ in
      completedOperations.append(exp)
      exp.fulfill()
    }

    XCTAssertEqual(completedOperations.count, 0, "Expected insert not to block further code execution (asyncronous)")
    wait(for: [exp], timeout: 3.0)
    XCTAssertEqual(completedOperations, [exp], "Expected insert to complete after timeout")
  }
  
  func test_insert_deliversErrorOnInsertionError() {
    let invalidStoreURL = URL(string: "invalid://store-url")!
    let sut = makeSUT(storeURL: invalidStoreURL)
    let insertionFeed = uniqueFeedImages().local
    let insertionTimestamp = Date()
    
    let insertionError = insert((feed: insertionFeed, timestamp: insertionTimestamp), to: sut)
    
    XCTAssertNotNil(insertionError, "Expected to insert with error")
  }
  
  func test_insert_hasNoSideEffectsOnInsertionError() {
    let invalidStoreURL = URL(string: "invalid://store-url")!
    let sut = makeSUT(storeURL: invalidStoreURL)
    let insertionFeed = uniqueFeedImages().local
    let insertionTimestamp = Date()
    
    insert((feed: insertionFeed, timestamp: insertionTimestamp), to: sut)
    
    expect(sut, toRetrieve: .empty)
  }
 
  
  func test_delete_hasNoSideEffectsOnEmptyCache() {
    let sut = makeSUT()
    
    let deletionError = deleteCache(from: sut)
    
    XCTAssertNil(deletionError, "Expected to delete successfully")
    expect(sut, toRetrieve: .empty)
  }
  
  func test_delete_cleansPreviouslyInsertedCache() {
    let sut = makeSUT()
    insert((feed: uniqueFeedImages().local, timestamp: Date()), to: sut)
    
    let deletionError = deleteCache(from: sut)
    
    XCTAssertNil(deletionError, "Expect non-empty cache deletion to succeed")
    expect(sut, toRetrieve: .empty)
  }
 
  func test_delete_runAsyncronously() {
    let sut = makeSUT()
    var completedOperations = [XCTestExpectation]()
    let exp = expectation(description: "Wait until delete completes")

    sut.deleteCachedFeed { _ in
      completedOperations.append(exp)
      exp.fulfill()
    }

    XCTAssertEqual(completedOperations.count, 0, "Expected delete not to block further code execution (asyncronous)")
    wait(for: [exp], timeout: 3.0)
    XCTAssertEqual(completedOperations, [exp], "Expected delete to complete after timeout")
  }
  
  func test_delete_deliversNoErrorOnEmptyCache() {
    let sut = makeSUT()
    
    let deletionError = deleteCache(from: sut)
    
    XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
  }
  
  func test_delete_deliversNoErrorOnNonEmptyCache() {
    let sut = makeSUT()
    insert((uniqueFeedImages().local, Date()), to: sut)
    
    let deletionError = deleteCache(from: sut)
    
    XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
  }
 
  func test_delete_deliversErrorOnDeletionError() {
    let noDeletePermissionURL = cachesDirectoryURL()
    let sut = makeSUT(storeURL: noDeletePermissionURL)
    
    let deletionError = deleteCache(from: sut)
    
    XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
  }
  
  func test_delete_hasNoSideEffectsOnDeletionError() {
    let noDeletePermissionURL = cachesDirectoryURL()
    let sut = makeSUT(storeURL: noDeletePermissionURL)
    
    deleteCache(from: sut)
    
    expect(sut, toRetrieve: .empty)
  }
  
  
  func test_storeSideEffects_runSerially() {
    let sut = makeSUT()
    var completedOperationsInOrder = [XCTestExpectation]()
    
    let op1 = expectation(description: "Operation 1")
    sut.insert(uniqueFeedImages().local, timestamp: Date()) { _ in
      completedOperationsInOrder.append(op1)
      op1.fulfill()
    }
    
    let op2 = expectation(description: "Operation 2")
    sut.deleteCachedFeed { _ in
      completedOperationsInOrder.append(op2)
      op2.fulfill()
    }
    
    let op3 = expectation(description: "Operation 3")
    sut.insert(uniqueFeedImages().local, timestamp: Date()) { _ in
      completedOperationsInOrder.append(op3)
      op3.fulfill()
    }
    
    waitForExpectations(timeout: 5.0)
    XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects operations to run serially, but operation finished in wrong order")
  }
  
  // MARK: - Helpers
  
  private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
    let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
  }
  
  private func testSpecificStoreURL() -> URL {
    cachesDirectoryURL().appendingPathComponent("\(type(of: self)).store")
  }
  
  private func cachesDirectoryURL() -> URL {
    FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
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
  
  @discardableResult
  private func insert(_ insertion: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
    let exp = expectation(description: "Wait until insert is completed")
    
    var capturedError: Error?
    sut.insert(insertion.feed, timestamp: insertion.timestamp) { insertionError in
      capturedError = insertionError
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
    return capturedError
  }
  
  @discardableResult
  private func deleteCache(from sut: FeedStore) -> Error? {
    let exp = expectation(description: "Wait until delete is completed")
    
    var capturedError: Error?
    sut.deleteCachedFeed { deletionError in
      capturedError = deletionError
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
    return capturedError
  }
  
  private func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrievalResult, file:StaticString = #filePath, line: UInt = #line) {
    expect(sut, toRetrieve: expectedResult, file: file, line: line)
    expect(sut, toRetrieve: expectedResult, file: file, line: line)
  }
  
  private func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrievalResult, file:StaticString = #filePath, line: UInt = #line) {
    let exp = expectation(description: "Wait till retrieve completes")
    sut.retrieve { actualResult in
      switch (expectedResult, actualResult) {
      case (.empty, .empty),
           (.failure, .failure):
        break
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
