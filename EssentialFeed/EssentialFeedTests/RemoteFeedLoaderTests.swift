//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 20.04.2021.
//

import XCTest

class RemoteFeedLoader {
  func load() {
    HTTPClient.shared.get(url: URL(string: "https://a-url.com"))
  }
}

class HTTPClient {
  static var shared = HTTPClient()
  
  func get(url: URL?) {
    
  }
}

class HTTPClientSpy: HTTPClient {
  var requestUrl: URL?
  
  override func get(url: URL?) {
    requestUrl = url
  }
}

class RemoteFeedLoaderTests: XCTestCase {
  
  func test_init_doesNotHaveUrl() {
    let client = HTTPClientSpy()
    _ = RemoteFeedLoader()
    
    XCTAssertNil(client.requestUrl)
  }
  
  func test_load_hasUrl() {
    let client = HTTPClientSpy()
    HTTPClient.shared = client
    let sut = RemoteFeedLoader()
    
    sut.load()
    
    XCTAssertNotNil(client.requestUrl)
  }
  
}
