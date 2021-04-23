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
    
    expect(sut, delivers: .connectivity) {
      let clientError = NSError(domain: "Test", code: 0)
      client.complete(with: clientError)
    }
  }
  
  func test_load_deliversErrorOnNon200HTTPResponse() {
    let (sut, client) = makeSUT()
    
    let samples = [199, 201, 300, 400, 500]
    samples.enumerated().forEach { index, code in
      expect(sut, delivers: .invalidData) {
        client.complete(with: code, at: index)
      }
    }
  }
  
  func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
    let (sut, client) = makeSUT()
    
    expect(sut, delivers: .invalidData) {
      let invalidJSON = Data("invalid data".utf8)
      client.complete(with: 200, data: invalidJSON)
    }
  }
  
  // MARK: - Helpers
  
  private func makeSUT(url: URL = URL(string: "https://a-given-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(client: client, url: url)
    return (sut: sut, client: client)
  }
  
  private func expect(_ sut: RemoteFeedLoader, delivers error: RemoteFeedLoader.Error, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
    var capturedResults = [RemoteFeedLoader.Result]()
    sut.load() { capturedResults.append($0) }
    
    action()
    
    XCTAssertEqual(capturedResults, [.failure(error)], file: file, line: line)
  }
  
  private class HTTPClientSpy: HTTPClient {
    var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
    
    var requestedUrls: [URL] {
      return messages.map { $0.url }
    }
    
    func get(url: URL, completion: @escaping (HTTPClientResult) -> Void) {
      messages.append((url: url, completion: completion))
    }
    
    func complete(with clientError: Error, at index: Int = 0) {
      messages[index].completion(.failure(clientError))
    }
    
    func complete(with statusCode: Int, data: Data = Data(), at index: Int = 0) {
      let response = HTTPURLResponse(url: requestedUrls[index],
                                     statusCode: statusCode,
                                     httpVersion: nil,
                                     headerFields: nil)!
      messages[index].completion(.success(response, data))
    }
  }
}
