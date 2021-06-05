//
//  LocalFeedItem.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 05.06.2021.
//

import Foundation

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
