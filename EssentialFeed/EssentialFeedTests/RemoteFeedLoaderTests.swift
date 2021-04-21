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
    
    sut.load { _ in }
    
    XCTAssertEqual(client.requestedUrls, [url])
  }
  
  func test_loadTwice_requestsDataFromUrlTwice() {
    let url = URL(string: "https://a-given-url.com")!
    let (sut, client) = makeSUT(url: url)
    
    sut.load { _ in }
    sut.load { _ in }
    
    XCTAssertEqual(client.requestedUrls, [url, url])
  }
  
  func test_load_deliversErrorOnClientError() {
    let (sut, client) = makeSUT()
    
    var capturedErrors = [RemoteFeedLoader.Error]()
    sut.load() { capturedErrors.append($0) }
    
    let clientError = NSError(domain: "Test", code: 0)
    client.complete(with: clientError)
    
    XCTAssertEqual(capturedErrors, [.connectivity])
  }
  
  // MARK: - Helpers
  
  private func makeSUT(url: URL = URL(string: "https://a-given-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(client: client, url: url)
    return (sut: sut, client: client)
  }
  
  private class HTTPClientSpy: HTTPClient {
    var messages = [(url: URL, completion: (Error) -> Void)]()
    
    var requestedUrls: [URL] {
      return messages.map { $0.url }
    }
    
    func get(url: URL, completion: @escaping (Error) -> Void) {
      messages.append((url: url, completion: completion))
    }
    
    func complete(with clientError: Error, at index: Int = 0) {
      messages[index].completion(clientError)
    }
  }
}
