//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 14.06.2021.
//

import Foundation

internal final class FeedCachePolicy {
  private init() {}
  
  private static let calendar = Calendar(identifier: .gregorian)
  private static var maxCacheAgeInDays: Int {
    return 7
  }
  
  internal static func validate(_ timestamp: Date, against currentDate: Date) -> Bool {
    guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
      return false
    }
    return currentDate < maxCacheAge
  }
  
}
