//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 20.04.2021.
//

import Foundation

public enum LoadFeedResult {
  case success([FeedImage])
  case failure(Error)
}

public protocol FeedLoader {
  func load(completion: @escaping (LoadFeedResult) -> Void)
}
