//
//  Post.swift
//  Showcase-app
//
//  Created by Aris Doxakis on 2/2/16.
//  Copyright © 2016 DASoftware. All rights reserved.
//

import Foundation
import Firebase

class Post {
    private var _postDescription: String!
    private var _postImgUrl: String?
    private var _postLikes: Int!
    private var _username: String!
    private var _postKey: String!
    private var _postRef: Firebase!
    
    var postDescription: String {
        return _postDescription
    }
    
    var postImgUrl: String? {
        return _postImgUrl
    }
    
    var postLikes: Int {
        return _postLikes
    }
    
    var postUsername: String {
        return _username
    }
    
    var postKey: String {
        return _postKey
    }
    
    init(description: String, imageUrl: String?, username: String) {
        self._postDescription = description
        self._postImgUrl = imageUrl
        self._username = username
    }
    
    init(postKey: String, dictionary: Dictionary<String, AnyObject>) {
        self._postKey = postKey
        
        if let likes = dictionary["likes"] as? Int {
            self._postLikes = likes
        }
        
        if let imgUrl = dictionary["img_url"] as? String {
            self._postImgUrl = imgUrl
        }
        
        if let descr = dictionary["description"] as? String {
            self._postDescription = descr
        }
        
        self._postRef = DataService.ds.REF_POSTS.childByAppendingPath(self._postKey)
    }
    
    func adjustLikes(addLike: Bool) {
        if addLike == true {
            _postLikes = _postLikes + 1
        } else {
            _postLikes = _postLikes - 1
        }
        
        _postRef.childByAppendingPath("likes").setValue(_postLikes)
    }
}