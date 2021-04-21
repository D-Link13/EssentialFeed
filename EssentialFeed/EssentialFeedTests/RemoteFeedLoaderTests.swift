//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 20.04.2021.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
  func test_init_doesNotRequestDataFromUrl() {
    let (_, client) = makeSUT()
    
    XCTAssertNil(client.requestUrl)
  }
  
  func test_load_requestDataFromUrl() {
    let url = URL(string: "https://a-given-url.com")!
    let (sut, client) = makeSUT(url: url)
    
    sut.load()
    
    XCTAssertEqual(client.requestUrl, url)
  }
  
  // MARK: - Helpers
  
  private func makeSUT(url: URL = URL(string: "https://a-given-url.com")!
) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(client: client, url: url)
    return (sut: sut, client: client)
  }
  
  private class HTTPClientSpy: HTTPClient {
    var requestUrl: URL?
    
    func get(url: URL?) {
      requestUrl = url
    }
  }
}
