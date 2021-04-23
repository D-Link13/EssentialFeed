//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 21.04.2021.
//

import Foundation

public enum HTTPClientResult {
  case success(HTTPURLResponse, Data)
  case failure(Error)
}

public protocol HTTPClient {
  func get(url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader {
  private let client: HTTPClient
  private let url: URL
  
  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }
  
  public enum Result: Equatable {
    case success([FeedItem])
    case failure(Error)
  }
  
  public init(client: HTTPClient, url: URL) {
    self.client = client
    self.url = url
  }
  
  public func load(completion: @escaping (Result) -> Void) {
    client.get(url: self.url) { result in
      switch result {
      case let .success(_, data):
        if let _ = try? JSONSerialization.jsonObject(with: data, options: []) {
          completion(.success([]))
        } else {
          completion(.failure(.invalidData))
        }
      case .failure:
        completion(.failure(.connectivity))
      }
    }
  }
}
