//
//  LocalFeedTests+Helpers.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 10.06.2021.
//

import Foundation
import EssentialFeed

func uniqueFeedImage() -> FeedImage {
  return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
}

func uniqueFeedImages() -> (models: [FeedImage], local: [LocalFeedImage]) {
  let models = [uniqueFeedImage(), uniqueFeedImage()]
  let local = models.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
  return (models, local)
}
