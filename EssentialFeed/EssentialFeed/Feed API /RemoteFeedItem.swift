//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 05.06.2021.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
  internal let id: UUID
  internal let description: String?
  internal let location: String?
  internal let image: URL
}
