//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 26.04.2021.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
  internal let id: UUID
  internal let description: String?
  internal let location: String?
  internal let image: URL
}

internal final class FeedItemsMapper {
  private struct Root: Decodable {
    let items: [RemoteFeedItem]
  }
  
  private static let OK_200 = 200
  
  internal static func map(_ response: HTTPURLResponse, data: Data) throws -> [RemoteFeedItem] {
    guard response.statusCode == OK_200,
          let root = try? JSONDecoder().decode(Root.self, from: data) else {
      throw RemoteFeedLoader.Error.invalidData
    }
    return root.items
  }
}
