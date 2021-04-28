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
    session.dataTask(with: url) { _, _, _ in }.resume()
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
  
  func test_getFromUrl_resumesDataTaskWithUrl() {
    let url = URL(string: "https://any-url.com")!
    let session = URLSessionSpy()
    let task = URLSessionDataTaskSpy()
    session.stub(url, task: task)
    let sut = UrlSessionHTTPClient(session: session)
    
    sut.get(from: url)
    
    XCTAssertEqual(task.resumeCallCount, 1)
  }
}

class URLSessionSpy: URLSession {
  var receivedUrls = [URL]()
  private var stub = [URL: URLSessionDataTask]()
  
  func stub(_ url: URL, task: URLSessionDataTask) {
    stub[url] = task
  }
  
  override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
    receivedUrls.append(url)
    return stub[url] ?? FakeURLSessionDataTask()
  }
}

class FakeURLSessionDataTask: URLSessionDataTask {
  override func resume() {}
}

class URLSessionDataTaskSpy: URLSessionDataTask {
  var resumeCallCount = 0
  
  override func resume() {
    resumeCallCount += 1
  }
}
