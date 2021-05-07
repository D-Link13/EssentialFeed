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
  
  func test_getFromUrl_failsOnRequestError() {
    URLProtocolStub.startInterceptingRequests()
    let url = URL(string: "https://any-url.com")!
    let expectedError = NSError.init(domain: "any-error", code: 1)
    URLProtocolStub.stub(url, error: expectedError)
    
    let sut = UrlSessionHTTPClient()
    
    let exp = expectation(description: "Wait until get completes.")
    sut.get(from: url) { result in
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
    URLProtocolStub.stopInterceptingRequests()
  }
}

class URLProtocolStub: URLProtocol {
  private static var stub = [URL: Stub]()
  
  struct Stub {
    let data: Data?
    let response: URLResponse?
    let error: Error?
  }
  
  static func stub(_ url: URL, data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
    stub[url] = Stub(data: data, response: response, error: error)
  }
  
  override class func canInit(with request: URLRequest) -> Bool {
    if let url = request.url, let _ = URLProtocolStub.stub[url] {
      return true
    } else {
      return false
    }
  }
  
  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }
  
  override func startLoading() {
    guard let url = request.url, let stub = URLProtocolStub.stub[url] else { return }
    
    if let data = stub.data {
      client?.urlProtocol(self, didLoad: data)
    }
    if let response = stub.response {
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    }
    if let error = stub.error {
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
    stub = [:]
  }
}

