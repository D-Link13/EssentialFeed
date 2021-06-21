//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 21.06.2021.
//

import Foundation

public class CodableFeedStore: FeedStore {
  
  private struct Cache: Codable {
    var feed: [CodableFeedImage]
    var timestamp: Date
    
    var localFeed: [LocalFeedImage] { feed.map { $0.local } }
  }
  
  private struct CodableFeedImage: Codable {
    private let id: UUID
    private let description: String?
    private let location: String?
    private let url: URL
    
    init(local: LocalFeedImage) {
      self.id = local.id
      self.description = local.description
      self.location = local.location
      self.url = local.url
    }
    
    var local: LocalFeedImage {
      LocalFeedImage(id: id, description: description, location: location, url: url)
    }
  }
  
  private let storeURL: URL
  
  public init(storeURL: URL) {
    self.storeURL = storeURL
  }
  
  public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
    let codableFeed = feed.map { CodableFeedImage(local: $0) }
    do {
      let cache = Cache(feed: codableFeed, timestamp: timestamp)
      let encoder = JSONEncoder()
      let data = try encoder.encode(cache)
      try data.write(to: storeURL)
      completion(nil)
    } catch {
      completion(error)
    }
  }
  
  public func retrieve(completion: @escaping RetrieveCompletion) {
    guard let data = try? Data.init(contentsOf: storeURL) else {
      completion(.empty)
      return
    }
    do {
      let decoder = JSONDecoder()
      let cache = try decoder.decode(Cache.self, from: data)
      completion(.found(cache.localFeed, cache.timestamp))
    } catch {
      completion(.failure(error))
    }
  }
  
  public func deleteCachedFeed(_ completion: @escaping DeleteCompletion) {
    guard FileManager.default.fileExists(atPath: storeURL.path) else {
      completion(nil)
      return
    }
    do {
      try FileManager.default.removeItem(at: storeURL)
      completion(nil)
    } catch {
      completion(error)
    }
  }
  
}
