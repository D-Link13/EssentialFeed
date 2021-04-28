//
//  UrlSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 28.04.2021.
//

import XCTest

class UrlSessionHTTPClient {
  var session: URLSession
  
  init(session: URLSession) {
    self.session = session
  }
  
  func get(from url: URL) {
    session.dataTask(with: url) { _, _, _ in }
  }
}

class UrlSessionHTTPClientTests: XCTestCase {
  
  func test_getFromUrl_createsDataTaskWithUrl() {
    let url = URL(string: "https://any-url.com")!
    let session = URLSessionSpy()
    let sut = UrlSessionHTTPClient(session: session)
    
    sut.get(from: url)
    
    XCTAssertEqual(session.receivedUrls, [url])
  }
}

class URLSessionSpy: URLSession {
  var receivedUrls = [URL]()
  
  override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
    receivedUrls.append(url)
    return FakeURLSessionDataTask()
  }
}

class FakeURLSessionDataTask: URLSessionDataTask {}
