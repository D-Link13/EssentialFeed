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
  
  private let currentDate: CurrentDateProvider
  private let store: FeedStore
  
  public init(store: FeedStore, currentDate: @escaping CurrentDateProvider) {
    self.store = store
    self.currentDate = currentDate
  }
  
  private func cache(_ items: [FeedItem], completion: @escaping (Error?) -> ()) {
    store.insert(items: items.toLocal(), timestamp: self.currentDate()) { [weak self] error in
      guard self != nil else { return }
      completion(error)
    }
  }
  
  public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
    store.deleteCachedFeed() { [weak self] error in
      guard let self = self else { return }
      if let cacheDeletionError = error {
        completion(cacheDeletionError)
      } else {
        self.cache(items, completion: completion)
      }
    }
  }
  
}

extension Array where Element == FeedItem {
  func toLocal() -> [LocalFeedItem] {
    return map { LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageUrl: $0.imageUrl)}
  }
  
}
