//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 20.04.2021.
//

import XCTest

class RemoteFeedLoader {
  let client: HTTPClient
  let url: URL
  
  init(client: HTTPClient, url: URL) {
    self.client = client
    self.url = url
  }
  func load() {
    client.get(url: self.url)
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
    let url = URL(string: "https://a-url.com")!
    _ = RemoteFeedLoader(client: client, url: url)
    
    XCTAssertNil(client.requestUrl)
  }
  
  func test_load_hasUrl() {
    let client = HTTPClientSpy()
    let url = URL(string: "https://a-given-url.com")!
    let sut = RemoteFeedLoader(client: client, url: url)
    
    sut.load()
    
    XCTAssertEqual(client.requestUrl, url)
  }
  
}
