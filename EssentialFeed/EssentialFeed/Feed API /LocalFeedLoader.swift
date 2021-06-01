//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 30.05.2021.
//

import Foundation

public final class LocalFeedLoader {
  public typealias CurrentDateProvider = () -> Date
  
  private let currentDate: CurrentDateProvider
  private let store: FeedStore
  
  public init(store: FeedStore, currentDate: @escaping CurrentDateProvider) {
    self.store = store
    self.currentDate = currentDate
  }
  
  private func cache(_ items: [FeedItem], completion: @escaping (Error?) -> ()) {
    store.insert(items: items, timestamp: self.currentDate()) { [weak self] error in
      guard self != nil else { return }
      completion(error)
    }
  }
  
  public func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
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
