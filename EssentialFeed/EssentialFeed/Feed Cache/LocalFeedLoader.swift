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
  private let calendar = Calendar(identifier: .gregorian)
  
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
    store.retrieve { [weak self] result in
      guard let self = self else { return }
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case let .found(cache, timestamp) where self.validate(timestamp):
        completion(.success(cache.toModels()))
      case .found:
        completion(.success([]))
      case .empty:
        completion(.success([]))
      }
    }
  }
  
  public func validateCache() {
    store.retrieve { [unowned self] result in
      switch result {
      case .failure:
        self.store.deleteCachedFeed { _ in }
      case .found(_, let timestamp) where !self.validate(timestamp):
        self.store.deleteCachedFeed { _ in }
      case .found, .empty:
        break
      }
    }
  }
  
  private var maxCacheAgeInDays: Int {
    return 7
  }
  
  private func validate(_ timestamp: Date) -> Bool {
    guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
      return false
    }
    return currentDate() < maxCacheAge
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
