//
//  PostsFrontPageModel.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 10/12/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import Combine

class PostsFrontPageModel: NSObject {
    var newDataLoaded: (([LemmyModel.PostView]) -> Void)?
    var dataLoaded: (([LemmyModel.PostView]) -> Void)?
    
    private let upvoteDownvoteService = UpvoteDownvoteRequestService(userAccountService: UserAccountService())
    private let contentPreferenceService = ContentPreferencesStorageManager()
    
    private var cancellable = Set<AnyCancellable>()
    
    var isFetchingNewContent = false
    var currentPage = 1
    
    var postsDataSource: [LemmyModel.PostView] = []
    
    var currentSortType: LemmySortType {
        get { contentPreferenceService.contentSortType }
        set {
            self.currentPage = 1
            contentPreferenceService.contentSortType = newValue
        }
    }
    
    var currentListingType: LemmyPostListingType {
        get { contentPreferenceService.listingType }
        set {
            self.currentPage = 1
            contentPreferenceService.listingType = newValue
        }
    }
    
    func loadPosts() {
        let parameters = LemmyModel.Post.GetPostsRequest(type: self.currentListingType,
                                                         sort: self.currentSortType,
                                                         page: 1,
                                                         limit: 50,
                                                         communityId: nil,
                                                         communityName: nil,
                                                         auth: LemmyShareData.shared.jwtToken)
        
        ApiManager.requests.asyncGetPosts(parameters: parameters)
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                Logger.logCombineCompletion(completion)
            } receiveValue: { (response) in
                self.postsDataSource = response.posts
                self.dataLoaded?(response.posts)
            }.store(in: &cancellable)
    }
    
    func loadMorePosts(completion: @escaping (() -> Void)) {
        let parameters = LemmyModel.Post.GetPostsRequest(type: self.currentListingType,
                                                         sort: self.currentSortType,
                                                         page: self.currentPage,
                                                         limit: 50,
                                                         communityId: nil,
                                                         communityName: nil,
                                                         auth: LemmyShareData.shared.jwtToken)
        
        ApiManager.requests.asyncGetPosts(parameters: parameters)
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                Logger.logCombineCompletion(completion)
            } receiveValue: { (response) in
                self.newDataLoaded?(response.posts)
                completion()
                
            }.store(in: &cancellable)
    }
    
    func receiveMessages() {
        let message = """
        {"op": "GetPosts","data": {
      "limit" : 50,
      "type_" : "All",
      "sort" : "Active",
      "auth" : "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6MTQxNjUsImlzcyI6ImxlbW15Lm1sIn0.NNTF0FbKEyG-y1fPqvccQ8ut-rBCyYEncU5LbHv-CTE",
      "page" : 1
    }}
"""
        ApiManager.requests.wsClient.send(message: .string(message))
        print(ApiManager.requests.wsClient.subject)
        ApiManager.requests.wsClient.subject
            .sink { (completion) in
                print(completion)
            } receiveValue: { (message) in
                switch message {
                case .string(let value):
                    let op = value.dictionary!["op"] as! String
                    let type: LemmyModel.Post.GetPostsResponse.Type = WSResponseMapper(op: op)!
                    
                    let decoder = LemmyJSONDecoder()
                    
                    do {
                        let response = try? decoder.decode(type, from: value.data(using: .utf8)!)
                        print(response)
                    } catch {
                        print(error)
                    }
                case .data: break
                @unknown default:
                    break
                }
            }.store(in: &cancellable)
        
    }
    
    func getPost(by id: LemmyModel.PostView.ID) -> LemmyModel.PostView? {
        if let index = postsDataSource.firstIndex(where: { $0.id == id }) {
            return postsDataSource[index]
        }
        
        return nil
    }
    
    private func saveNewPost(_ post: LemmyModel.PostView) {
        postsDataSource.updateElementById(post)
    }
    
    func createPostLike(newVote: LemmyVoteType, post: LemmyModel.PostView) {
        self.upvoteDownvoteService.createPostLike(vote: newVote, post: post)
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                Logger.logCombineCompletion(completion)
            } receiveValue: { (post) in
                self.saveNewPost(post)
            }.store(in: &cancellable)
    }
}

extension PostsFrontPageModel: FrontPageHeaderCellDelegate {
    func contentTypeChanged(to content: LemmyContentType) {
        
    }
}
