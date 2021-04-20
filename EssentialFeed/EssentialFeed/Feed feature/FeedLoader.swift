//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 20.04.2021.
//

import Foundation

enum LoadFeedResult {
  case success([FeedItem])
  case error(Error)
}

protocol FeedLoader {
  func load(completion: @escaping (LoadFeedResult) -> Void)
}
