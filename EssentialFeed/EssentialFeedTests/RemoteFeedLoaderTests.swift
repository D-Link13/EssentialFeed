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
    
    XCTAssertTrue(client.requestedUrls.isEmpty)
  }
  
  func test_load_requestsDataFromUrl() {
    let url = URL(string: "https://a-given-url.com")!
    let (sut, client) = makeSUT(url: url)
    
    sut.load()
    
    XCTAssertEqual(client.requestedUrls, [url])
  }
  
  func test_loadTwice_requestsDataFromUrlTwice() {
    let url = URL(string: "https://a-given-url.com")!
    let (sut, client) = makeSUT(url: url)
    
    sut.load()
    sut.load()
    
    XCTAssertEqual(client.requestedUrls, [url, url])
  }
  
  func test_load_deliversErrorOnClientError() {
    let (sut, client) = makeSUT()
    
    client.error = NSError(domain: "test", code: 0)
    var capturedError: RemoteFeedLoader.Error?
    sut.load() { error in
      capturedError = error
    }
    
    XCTAssertEqual(capturedError, .connectivity)
  }
  
  // MARK: - Helpers
  
  private func makeSUT(url: URL = URL(string: "https://a-given-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(client: client, url: url)
    return (sut: sut, client: client)
  }
  
  private class HTTPClientSpy: HTTPClient {
    var requestedUrls = [URL]()
    var error: Error?
    
    func get(url: URL, completion: @escaping (Error) -> Void) {
      if let error = self.error {
        completion(error)
      }
      requestedUrls.append(url)
    }
  }
}
