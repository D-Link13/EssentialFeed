//
//  UrlSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 28.04.2021.
//

import XCTest
import EssentialFeed

protocol HTTPSession {
  func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
  func resume()
}

class UrlSessionHTTPClient {
  var session: HTTPSession
  
  init(session: HTTPSession) {
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
  func test_getFromUrl_resumesDataTaskWithUrl() {
    let url = URL(string: "https://any-url.com")!
    let session = HTTPSessionSpy()
    let task = HTTPSessionTaskSpy()
    session.stub(url, task: task)
    let sut = UrlSessionHTTPClient(session: session)
    
    sut.get(from: url) { _ in }
    
    XCTAssertEqual(task.resumeCallCount, 1)
  }
  
  func test_getFromUrl_failsOnRequestError() {
    let url = URL(string: "https://any-url.com")!
    let session = HTTPSessionSpy()
    let expectedError = NSError(domain: "test", code: 0)
    session.stub(url, error: expectedError)
    let sut = UrlSessionHTTPClient(session: session)
    
    let exp = expectation(description: "Wait until get completes.")
    
    sut.get(from: url) { result in
      switch result {
      case .failure(let receivedError as NSError):
        XCTAssertEqual(receivedError, expectedError)
      default:
        XCTFail("Excpected failure with error: \(expectedError), got \(result) instead.")
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
  }
}

class HTTPSessionSpy: HTTPSession {
  private var stub = [URL: Stub]()
  
  struct Stub {
    var task: HTTPSessionTask
    var error: Error?
  }
  
  func stub(_ url: URL, task: HTTPSessionTask = FakeHTTPSessionTask(), error: Error? = nil) {
    stub[url] = Stub(task: task, error: error)
  }
  
  func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
    guard let stub = stub[url] else {
      fatalError("Couldn't find stub for url!")
    }
    completionHandler(nil, nil, stub.error)
    return stub.task 
  }
}

class FakeHTTPSessionTask: HTTPSessionTask {
  func resume() {}
}

class HTTPSessionTaskSpy: HTTPSessionTask {
  var resumeCallCount = 0
  
  func resume() {
    resumeCallCount += 1
  }
}
