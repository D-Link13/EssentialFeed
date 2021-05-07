//
//  XCTestCase+MemoryLeakTracking.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 07.05.2021.
//

import Foundation
import XCTest

extension XCTestCase {
  func trackForMemoryLeaks(_ instance: AnyObject?, file: StaticString = #filePath, line: UInt = #line) {
    addTeardownBlock { [weak instance] in
      XCTAssertNil(instance, "Potential memory leak!", file: file, line: line)
    }
  }
}
