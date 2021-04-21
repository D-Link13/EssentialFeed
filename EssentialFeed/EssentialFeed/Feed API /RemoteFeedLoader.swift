//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 21.04.2021.
//

import Foundation

public protocol HTTPClient {
  func get(url: URL?)
}

public class RemoteFeedLoader {
  private let client: HTTPClient
  private let url: URL
  
  public init(client: HTTPClient, url: URL) {
    self.client = client
    self.url = url
  }
  public func load() {
    client.get(url: self.url)
  }
}
