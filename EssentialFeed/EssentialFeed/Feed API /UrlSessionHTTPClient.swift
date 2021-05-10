//
//  UrlSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 10.05.2021.
//

import Foundation

public class UrlSessionHTTPClient: HTTPClient {
  var session: URLSession
  
  public init(session: URLSession = .shared) {
    self.session = session
  }
  
  private struct UnexpectedCaseError: Error {}
  
  public func get(url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url) { data, response, error in
      if let error = error {
        completion(.failure(error))
      } else if let data = data, let response = response as? HTTPURLResponse {
        completion(.success(response, data))
      } else {
        completion(.failure(UnexpectedCaseError()))
      }
    }.resume()
  }
}
