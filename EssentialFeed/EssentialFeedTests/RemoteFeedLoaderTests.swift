//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 20.04.2021.
//

import XCTest

class RemoteFeedLoader {
  let client: HTTPClient
  
  init(client: HTTPClient) {
    self.client = client
  }
  func load() {
    client.get(url: URL(string: "https://a-url.com"))
  }
}

protocol HTTPClient {
  func get(url: URL?)
}

class HTTPClientSpy: HTTPClient {
  var requestUrl: URL?
  
  func get(url: URL?) {
    requestUrl = url
  }
}

class RemoteFeedLoaderTests: XCTestCase {
  
  func test_init_doesNotHaveUrl() {
    let client = HTTPClientSpy()
    _ = RemoteFeedLoader(client: client)
    
    XCTAssertNil(client.requestUrl)
  }
  
  func test_load_hasUrl() {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(client: client)
    
    sut.load()
    
    XCTAssertNotNil(client.requestUrl)
  }
  
}
