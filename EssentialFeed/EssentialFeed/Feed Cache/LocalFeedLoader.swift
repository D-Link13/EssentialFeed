//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 30.05.2021.
//

import Foundation

public final class LocalFeedLoader {
  public typealias CurrentDateProvider = () -> Date
  public typealias SaveResult = Error?
  public typealias LoadResult = LoadFeedResult
  
  private let currentDate: CurrentDateProvider
  private let store: FeedStore
  
  public init(store: FeedStore, currentDate: @escaping CurrentDateProvider) {
    self.store = store
    self.currentDate = currentDate
  }
  
  private func cache(_ feed: [FeedImage], completion: @escaping (Error?) -> ()) {
    store.insert(feed.toLocal(), timestamp: self.currentDate()) { [weak self] error in
      guard self != nil else { return }
      completion(error)
    }
  }
  
  public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
    store.deleteCachedFeed() { [weak self] error in
      guard let self = self else { return }
      if let cacheDeletionError = error {
        completion(cacheDeletionError)
      } else {
        self.cache(feed, completion: completion)
      }
    }
  }
  
  public func load(_ completion: @escaping (LoadResult) -> Void) {
    store.retrieve { error in
      if let error = error {
        completion(.failure(error))
      } else {
        completion(.success([]))
      }
    }
  }
  
}

extension Array where Element == FeedImage {
  func toLocal() -> [LocalFeedImage] {
    return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
  }
  
}
