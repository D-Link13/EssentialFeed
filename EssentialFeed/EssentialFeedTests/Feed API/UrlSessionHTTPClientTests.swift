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
  
  struct UnexpectedCaseError: Error {}
  
  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url) { data, response, error in
      if let error = error {
        completion(.failure(error))
      } else if let data = data, let response = response as? HTTPURLResponse {
        completion(.success(response, data))
      } else {
        completion(.failure(UnexpectedCaseError()))
      }
    }.resume()
  }
}

class UrlSessionHTTPClientTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    URLProtocolStub.startInterceptingRequests()
  }
  
  override func tearDown() {
    super.tearDown()
    URLProtocolStub.stopInterceptingRequests()
  }
  
  func test_getFromUrl_requestsCorrectUrl() {
    let url = anyURL()
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
    let expectedError = anyNSError()
    let receivedError = resultErrorFor(data: nil, response: nil, error: expectedError) as NSError?
    if let receivedNSError = receivedError {
      XCTAssertEqual(receivedNSError.domain, expectedError.domain)
      XCTAssertEqual(receivedNSError.code, expectedError.code)
    } else {
      XCTFail("Excpected failure with \(expectedError), got \(String(describing: receivedError)) instead.")
    }
  }

  func test_getFromUrl_failsOnInvalidRepresentationCases() {
    XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: nil, response: noHTTPResponse(), error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: nil, response: noHTTPResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: noHTTPResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: noHTTPResponse(), error: nil))
  }
  
  func test_getFromUrl_succeedsOnHTTPResponseWithData() {
    let data = anyData()
    let response = anyHTTPResponse()

    let resultValues = resultSuccessValuesFor(data: data, response: response, error: nil)
    
    XCTAssertEqual(resultValues?.response.url, response.url)
    XCTAssertEqual(resultValues?.response.statusCode, response.statusCode)
    XCTAssertEqual(resultValues?.data, data)
  }
    
  func test_getFromUrl_succeedsWithEmptyDataOnHTTPResponseWithNilData() {
    let response = anyHTTPResponse()
    
    let resultValues = resultSuccessValuesFor(data: nil, response: response, error: nil)
    
    let emptyData = Data()
    XCTAssertEqual(resultValues?.response.url, response.url)
    XCTAssertEqual(resultValues?.response.statusCode, response.statusCode)
    XCTAssertEqual(resultValues?.data, emptyData)
  }
  
  private func resultSuccessValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> (response:HTTPURLResponse, data:Data)? {
    let result = resultFor(data: data, response: response, error: error, file:file, line: line)
    
    switch result {
    case .success(let receivedResponse, let receivedData):
      return (receivedResponse, receivedData)
    default:
      XCTFail("Excpected success, got \(result) instead.", file:file, line:line)
      return nil
    }
  }
  
  private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error? {
    
    let result = resultFor(data: data, response: response, error: error, file:file, line: line)
    
    switch result {
    case .failure(let error):
      return error
    default:
      XCTFail("Excpected failure, got \(result) instead.", file:file, line:line)
      return nil
    }
  }
  
  private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> HTTPClientResult {
    
    URLProtocolStub.stub(data: data, response: response, error: error)
    let exp = expectation(description: "Wait until get completes.")
    
    var receivedResult:HTTPClientResult!
    makeSUT(file:file, line:line).get(from: anyURL()) { result in
      receivedResult = result
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
    return receivedResult
  }
  
  private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> UrlSessionHTTPClient {
    let sut = UrlSessionHTTPClient()
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
  }
  
  private func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
  }
  
  private func anyData() -> Data {
    return Data("any-data".utf8)
  }
  
  private func anyNSError() -> NSError {
    return NSError(domain: "any-error", code: 0, userInfo: nil)
  }
  
  private func anyHTTPResponse() -> HTTPURLResponse {
    return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
  }
  
  private func noHTTPResponse() -> URLResponse {
    return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
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
  
  static func stub(data: Data?, response: URLResponse?, error: Error?) {
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

