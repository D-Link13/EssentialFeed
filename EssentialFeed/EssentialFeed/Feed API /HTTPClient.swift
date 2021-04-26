//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 26.04.2021.
//

import Foundation

public enum HTTPClientResult {
  case success(HTTPURLResponse, Data)
  case failure(Error)
}

public protocol HTTPClient {
  func get(url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
