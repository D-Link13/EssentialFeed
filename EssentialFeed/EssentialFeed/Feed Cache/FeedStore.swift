//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 30.05.2021.
//

import Foundation

public protocol FeedStore {
  typealias DeleteCompletion = (Error?) -> Void
  typealias InsertCompletion = (Error?) -> Void
  
  func deleteCachedFeed(_ completion: @escaping DeleteCompletion)
  func insert(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertCompletion)
}

public struct LocalFeedItem: Equatable {
  public let id: UUID
  public let description: String?
  public let location: String?
  public let imageUrl: URL
  
  public init(id: UUID, description: String?, location: String?, imageUrl: URL) {
    self.id = id
    self.description = description
    self.location = location
    self.imageUrl = imageUrl
  }
}
