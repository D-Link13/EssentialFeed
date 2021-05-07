//
//  UrlSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 28.04.2021.
//

import XCTest
import EssentialFeed

class UrlSessionHTTPClient {
  var session: URLSession
  
  init(session: URLSession = .shared) {
    self.session = session
  }
  
  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url) { _, _, error in
      if let error = error {
        completion(.failure(error))
      }
    }.resume()
  }
}

class UrlSessionHTTPClientTests: XCTestCase {
  
  override class func setUp() {
    super.setUp()
    URLProtocolStub.startInterceptingRequests()
  }
  
  override class func tearDown() {
    super.tearDown()
    URLProtocolStub.stopInterceptingRequests()
  }
  
  func test_getFromUrl_requestsCorrectUrl() {
    let url = URL(string: "https://any-url.com")!
    let exp = expectation(description: "Wait until request will finish!")
    URLProtocolStub.observeRequests { request in
      XCTAssertEqual(request.url, url)
      XCTAssertEqual(request.httpMethod, "GET")
      exp.fulfill()
    }
    makeSUT().get(from: url) { _ in }
    wait(for: [exp], timeout: 1.0)
  }
  
  func test_getFromUrl_failsOnRequestError() {
    let url = URL(string: "https://any-url.com")!
    let expectedError = NSError.init(domain: "any-error", code: 1)
    URLProtocolStub.stub(error: expectedError)
    
    let exp = expectation(description: "Wait until get completes.")
    makeSUT().get(from: url) { result in
      switch result {
      case .failure(let receivedError as NSError):
        XCTAssertEqual(receivedError.domain, expectedError.domain)
        XCTAssertEqual(receivedError.code, expectedError.code)
      default:
        XCTFail("Excpected failure with error: \(expectedError), got \(result) instead.")
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
  }
  
  private func makeSUT() -> UrlSessionHTTPClient {
    return UrlSessionHTTPClient()
  }
}

class URLProtocolStub: URLProtocol {
  private static var stub: Stub?
  private static var observer: ((URLRequest) -> Void)?
  
  struct Stub {
    let data: Data?
    let response: URLResponse?
    let error: Error?
  }
  
  static func stub(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
    stub = Stub(data: data, response: response, error: error)
  }
  
  static func observeRequests(requestObserver: @escaping (URLRequest) -> Void) {
    observer = requestObserver
  }
  
  override class func canInit(with request: URLRequest) -> Bool {
    observer?(request)
    return true
  }
  
  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }
  
  override func startLoading() {
    if let data = URLProtocolStub.stub?.data {
      client?.urlProtocol(self, didLoad: data)
    }
    if let response = URLProtocolStub.stub?.response {
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    }
    if let error = URLProtocolStub.stub?.error {
      client?.urlProtocol(self, didFailWithError: error)
    }
    client?.urlProtocolDidFinishLoading(self)
  }
  
  override func stopLoading() {}
  
  class func startInterceptingRequests() {
    URLProtocol.registerClass(URLProtocolStub.self)
  }
  
  class func stopInterceptingRequests() {
    URLProtocol.unregisterClass(URLProtocolStub.self)
    stub = nil
    observer = nil
  }
}

