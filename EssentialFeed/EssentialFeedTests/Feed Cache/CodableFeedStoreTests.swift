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

class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs, AsyncronusFeedStoreSpecs {
  
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
    
    assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
  }
  
  func test_retrieveTwice_deliversEmptyOnEmptyCache() {
    let sut = makeSUT()
    
    assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
  }

  func test_retrieve_deliversFoundValuesAfterInsertion() {
    let sut = makeSUT()
    
    assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
  }
  
  func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
    let sut = makeSUT()
    
    assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
  }
  
  func test_retrieve_deliversFailureOnRetrieveError() {
    let storeURL = testSpecificStoreURL()
    let sut = makeSUT(storeURL: storeURL)
    try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
    
    assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
  }
  
  func test_retrieve_hasNoSideEffectsOnRetrieveError() {
    let storeURL = testSpecificStoreURL()
    let sut = makeSUT(storeURL: storeURL)
    try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
    
    assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
  }
  
  func test_retrieve_runsAsyncronously() {
    let sut = makeSUT()
    
    assertThatRetrieveRunsAsyncronusly(on: sut)
  }
  
  
  func test_insert_deliversNoErrorOnEmptyCache() {
    let sut = makeSUT()
    
    assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
  }
  
  func test_insert_deliversNoErrorOnNonEmptyCache() {
    let sut = makeSUT()
    
    assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
  }
  
  func test_insert_overridesPreviousInsertedCachedData() {
    let sut = makeSUT()
    
    assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
  }
  
  func test_insert_runAsyncronously() {
    let sut = makeSUT()
    
    assertThatInsertRunsAsyncronusly(on: sut)
  }

  func test_insert_deliversErrorOnInsertionError() {
    let invalidStoreURL = URL(string: "invalid://store-url")!
    let sut = makeSUT(storeURL: invalidStoreURL)
    
    assertThatInsertDeliversErrorOnInsertionError(on: sut)
  }
  
  func test_insert_hasNoSideEffectsOnInsertionError() {
    let invalidStoreURL = URL(string: "invalid://store-url")!
    let sut = makeSUT(storeURL: invalidStoreURL)
    
    assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
  }
 
  
  func test_delete_hasNoSideEffectsOnEmptyCache() {
    let sut = makeSUT()
    
    assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
  }
  
  func test_delete_cleansPreviouslyInsertedCache() {
    let sut = makeSUT()
    
    assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
  }
 
  func test_delete_runAsyncronously() {
    let sut = makeSUT()
    
    assertThatDeleteRunsAsyncronusly(on: sut)
  }
  
  func test_delete_deliversNoErrorOnEmptyCache() {
    let sut = makeSUT()
    
    assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
  }
  
  func test_delete_deliversNoErrorOnNonEmptyCache() {
    let sut = makeSUT()
    
    assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
  }
 
  func test_delete_deliversErrorOnDeletionError() {
    let noDeletePermissionURL = cachesDirectoryURL()
    let sut = makeSUT(storeURL: noDeletePermissionURL)
    
    assertThatDeleteDeliversErrorOnDeletionError(on: sut)
  }
  
  func test_delete_hasNoSideEffectsOnDeletionError() {
    let noDeletePermissionURL = cachesDirectoryURL()
    let sut = makeSUT(storeURL: noDeletePermissionURL)
    
    assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
  }
  
  
  func test_storeSideEffects_runSerially() {
    let sut = makeSUT()
    
    assertThatSideEffectsRunSerially(on: sut)
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
    FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!
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
