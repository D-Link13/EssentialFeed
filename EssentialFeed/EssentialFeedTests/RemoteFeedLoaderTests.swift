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
    
    expect(sut, delivers: .failure(.connectivity)) {
      let clientError = NSError(domain: "Test", code: 0)
      client.complete(with: clientError)
    }
  }
  
  func test_load_deliversErrorOnNon200HTTPResponse() {
    let (sut, client) = makeSUT()
    
    let samples = [199, 201, 300, 400, 500]
    samples.enumerated().forEach { index, code in
      expect(sut, delivers: .failure(.invalidData)) {
        client.complete(with: code, at: index)
      }
    }
  }
  
  func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
    let (sut, client) = makeSUT()
    
    expect(sut, delivers: .failure(.invalidData)) {
      let invalidJSON = Data("invalid data".utf8)
      client.complete(with: 200, data: invalidJSON)
    }
  }
  
  func test_load_deliversEmptyListOn200HTTPResponseWithEmptyJSON() {
    let (sut, client) = makeSUT()
    
    expect(sut, delivers: .success([])) {
      let validJSON = Data("{\"items\": []}".utf8)
      client.complete(with: 200, data: validJSON)
    }
  }
  
  func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
    let (sut, client) = makeSUT()
    
    let item1 = makeItemAndJSON(id: UUID(),
                            description: nil,
                            location: nil,
                            imageUrl: URL(string: "https://a-given-url.com")!)
    
    let item2 = makeItemAndJSON(id: UUID(),
                            description: "Description",
                            location: "Location",
                            imageUrl: URL(string: "https://a-given-url.com")!)
    
    let items = makeItems([item1.json, item2.json])
    
    expect(sut, delivers: .success([item1.model, item2.model])) {
      client.complete(with: 200, data: items)
    }
  }
  
  // MARK: - Helpers
  
  private func makeSUT(url: URL = URL(string: "https://a-given-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(client: client, url: url)
    return (sut: sut, client: client)
  }
  
  private func expect(_ sut: RemoteFeedLoader, delivers result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
    var capturedResults = [RemoteFeedLoader.Result]()
    sut.load() { capturedResults.append($0) }
    
    action()
    
    XCTAssertEqual(capturedResults, [result], file: file, line: line)
  }
  
  private func makeItemAndJSON(id: UUID, description: String?, location: String?, imageUrl: URL) -> (model: FeedItem, json: [String: Any]) {
    let model = FeedItem(
      id: id,
      description: description,
      location: location,
      imageUrl: imageUrl
    )
    
    let json = [
      "id": id.uuidString,
      "description": description,
      "location": location,
      "image": imageUrl.absoluteString
    ].compactMapValues { $0 }
    return (model: model, json: json)
  }
  
  private func makeItems(_ items: [[String: Any]]) -> Data {
    let json = ["items": items]
    return try! JSONSerialization.data(withJSONObject: json)
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
