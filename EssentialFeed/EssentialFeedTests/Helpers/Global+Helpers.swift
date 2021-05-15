//
//  Global+Helpers.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 15.05.2021.
//

import Foundation

func anyURL() -> URL {
  return URL(string: "https://any-url.com")!
}

func anyData() -> Data {
  return Data("any-data".utf8)
}

func anyNSError() -> NSError {
  return NSError(domain: "any-error", code: 0, userInfo: nil)
}

func anyHTTPResponse() -> HTTPURLResponse {
  return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
}

func noHTTPResponse() -> URLResponse {
  return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
}
