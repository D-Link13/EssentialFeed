//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 21.04.2021.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
  private let client: HTTPClient
  private let url: URL
  
  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }
  
  public typealias Result = LoadFeedResult
  
  public init(client: HTTPClient, url: URL) {
    self.client = client
    self.url = url
  }
  
  public func load(completion: @escaping (LoadFeedResult) -> Void) {
    client.get(url: self.url) { [weak self] result in
      guard self != nil else { return }
      switch result {
      case let .success(response, data):
        completion(RemoteFeedLoader.map(response, data: data))
      case .failure:
        completion(.failure(RemoteFeedLoader.Error.connectivity))
      }
    }
  }
  
  private static func map(_ response: HTTPURLResponse, data: Data) -> LoadFeedResult {
    do {
      let items = try FeedItemsMapper.map(response, data: data)
      return .success(items.toFeedItems())
    } catch let error {
      return .failure(error)
    }
  }
}

extension Array where Element == RemoteFeedItem {
  func toFeedItems() -> [FeedItem] {
    return map { FeedItem(id: $0.id, description: $0.description, location: $0.location, imageUrl: $0.image)}
  }
}
