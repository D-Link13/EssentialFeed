//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 30.05.2021.
//

import Foundation

private final class FeedCachePolicy {
  public typealias CurrentDateProvider = () -> Date
  
  private let currentDate: CurrentDateProvider
  private let calendar = Calendar(identifier: .gregorian)
  private var maxCacheAgeInDays: Int {
    return 7
  }
  
  init(currentDate: @escaping CurrentDateProvider) {
    self.currentDate = currentDate
  }
  
  func validate(_ timestamp: Date) -> Bool {
    guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
      return false
    }
    return currentDate() < maxCacheAge
  }
}

public final class LocalFeedLoader {
  private let store: FeedStore
  private let currentDate: () -> Date
  private let cachePolicy: FeedCachePolicy
  
  public init(store: FeedStore, currentDate: @escaping () -> Date) {
    self.store = store
    self.currentDate = currentDate
    self.cachePolicy = FeedCachePolicy(currentDate: currentDate)
  }
  
}
  
extension LocalFeedLoader {
  public typealias SaveResult = Error?
  
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
  
  private func cache(_ feed: [FeedImage], completion: @escaping (Error?) -> ()) {
    store.insert(feed.toLocal(), timestamp: self.currentDate()) { [weak self] error in
      guard self != nil else { return }
      completion(error)
    }
  }
  
}
  
extension LocalFeedLoader: FeedLoader {
  public typealias LoadResult = LoadFeedResult
  
  public func load(completion: @escaping (LoadResult) -> Void) {
    store.retrieve { [weak self] result in
      guard let self = self else { return }
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case let .found(cache, timestamp) where self.cachePolicy.validate(timestamp):
        completion(.success(cache.toModels()))
      case .found, .empty:
        completion(.success([]))
      }
    }
  }
  
}
  
extension LocalFeedLoader {
  public func validateCache() {
    store.retrieve { [weak self] result in
      guard let self = self else { return }
      switch result {
      case .failure:
        self.store.deleteCachedFeed { _ in }
      case .found(_, let timestamp) where !self.cachePolicy.validate(timestamp):
        self.store.deleteCachedFeed { _ in }
      case .found, .empty:
        break
      }
    }
  }
  
}

extension Array where Element == FeedImage {
  func toLocal() -> [LocalFeedImage] {
    return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
  }
  
}

extension Array where Element == LocalFeedImage {
  func toModels() -> [FeedImage] {
    return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
  }
  
}
