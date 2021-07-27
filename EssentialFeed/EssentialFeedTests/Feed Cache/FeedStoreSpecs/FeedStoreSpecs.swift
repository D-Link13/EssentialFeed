//
//  FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 27.07.2021.
//

import Foundation

protocol FeedStoreSpecs {
  func test_retrieve_deliversEmptyOnEmptyCache()
  func test_retrieveTwice_deliversEmptyOnEmptyCache()
  func test_retrieve_deliversFoundValuesAfterInsertion()
  func test_retrieve_hasNoSideEffectsOnNonEmptyCache()
  
  func test_insert_overridesPreviousInsertedCachedData()
  func test_insert_deliversNoErrorOnEmptyCache()
  func test_insert_deliversNoErrorOnNonEmptyCache()
  
  func test_delete_hasNoSideEffectsOnEmptyCache()
  func test_delete_deliversNoErrorOnEmptyCache()
  func test_delete_cleansPreviouslyInsertedCache()
  func test_delete_deliversNoErrorOnNonEmptyCache()
  
  func test_storeSideEffects_runSerially()
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
  func test_retrieve_deliversFailureOnRetrieveError()
  func test_retrieve_hasNoSideEffectsOnRetrieveError()
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
  func test_insert_deliversErrorOnInsertionError()
  func test_insert_hasNoSideEffectsOnInsertionError()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
  func test_delete_deliversErrorOnDeletionError()
  func test_delete_hasNoSideEffectsOnDeletionError()
}

typealias FailableFeedStoreSpecs = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs


protocol AsyncronusFeedStoreSpecs: FeedStoreSpecs {
  func test_retrieve_runsAsyncronously()
  func test_insert_runAsyncronously()
  func test_delete_runAsyncronously()
}
