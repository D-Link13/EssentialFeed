//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 20.04.2021.
//

import XCTest

class RemoteFeedLoader {
  func load() {
    HTTPClient.shared.requestUrl = URL(string: "https://a-url.com")
  }
}

class HTTPClient {
  static let shared = HTTPClient()
  private init() {}
  var requestUrl: URL?
}

class RemoteFeedLoaderTests: XCTestCase {
  
  func test_init_doesNotHaveUrl() {
    let client = HTTPClient.shared
    _ = RemoteFeedLoader()
    
    XCTAssertNil(client.requestUrl)
  }
  
  func test_load_hasUrl() {
    let client = HTTPClient.shared
    let sut = RemoteFeedLoader()
    
    sut.load()
    
    XCTAssertNotNil(client.requestUrl)
  }
  
}
