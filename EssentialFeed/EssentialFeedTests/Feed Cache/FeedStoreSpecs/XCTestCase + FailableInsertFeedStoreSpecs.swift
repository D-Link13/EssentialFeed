//
//  XCTestCase + FailableInsertFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 27.07.2021.
//

import XCTest
import EssentialFeed

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
  func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    let insertionError = insert((uniqueFeedImages().local, Date()), to: sut)
    
    XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error", file: file, line: line)
  }
  
  func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    insert((uniqueFeedImages().local, Date()), to: sut)
    
    expect(sut, toRetrieve: .empty, file: file, line: line)
  }
}
