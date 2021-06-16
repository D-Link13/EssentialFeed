//
//  LocalFeedImage.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 05.06.2021.
//

import Foundation

public struct LocalFeedImage: Equatable, Codable {
  public let id: UUID
  public let description: String?
  public let location: String?
  public let url: URL
  
  public init(id: UUID, description: String?, location: String?, url: URL) {
    self.id = id
    self.description = description
    self.location = location
    self.url = url
  }
}
