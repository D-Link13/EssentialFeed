//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 20.04.2021.
//

import Foundation

public struct FeedItem: Equatable {
  var id: UUID
  var description: String?
  var location: String?
  var imageUrl: URL
}
