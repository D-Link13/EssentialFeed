//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 26.04.2021.
//

import Foundation

internal class FeedItemsMapper {
  private struct Root: Decodable {
    let items: [Item]
  }

  private struct Item: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
    
    var item: FeedItem {
      return FeedItem(id: id, description: description, location: location, imageUrl: image)
    }
  }
  
  private static let OK_200 = 200
  
  internal static func map(_ response: HTTPURLResponse, data: Data) throws -> [FeedItem] {
    guard response.statusCode == OK_200 else {
      throw RemoteFeedLoader.Error.invalidData
    }
    let root = try JSONDecoder().decode(Root.self, from: data)
    return root.items.map { $0.item }
  }
}
