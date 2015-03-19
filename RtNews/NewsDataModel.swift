import Foundation

import Realm
import UIKit // NSAttributedString


// notifications

let newsItemsLoadedNotification = "newsItemsLoadedNotification"
let newsItemsLoadErrorNotification = "newsItemsLoadErrorNotification"

let newsExtendedItemsFetchedNotification = "newsExtendedItemsFetchedNotification"
let newsItemDetailsFetchedNotification = "newsItemDetailsFetchedNotification"
let newsItemLikeStateFetchedNotification = "newsItemLikeStateFetchedNotification"

let newsItemFetchedNotification = "newsItemFetchedNotification"


// realm entities

class RLMNewsItem: RLMObject {
    dynamic var id = ""
    dynamic var title = ""
    dynamic var time = NSDate()
    dynamic var image = ""
    dynamic var url = ""
    dynamic var like_count = 0
    dynamic var liked = false
    dynamic var like_accepted = false
    dynamic var summary = ""
    

    override class func primaryKey() -> String {
        return "id"
    }
    
    override class func createOrUpdateInRealm(realm: RLMRealm!, withObject object: AnyObject!) -> RLMNewsItem {
        let dict = object.mutableCopy() as! NSMutableDictionary
        let time = dict["time"] as! String
        dict.removeObjectForKey("time")
        
        let parsedItem = super.createOrUpdateInRealm(realm, withObject: dict) as! RLMNewsItem
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
        parsedItem.time = dateFormatter.dateFromString(time) ?? NSDate(timeIntervalSince1970: 0)
        
        return parsedItem
    }
    
    func item() -> NewsItem {
        return NewsItem(
            id: id,
            title: title,
            time: time,
            image: image,
            url: url,
            like_count: like_count,
            summary: summary
        )
    }
}

class RLMNewsItemDetails: RLMObject {
    dynamic var id = ""
    dynamic var text = ""
    
    override class func primaryKey() -> String {
        return "id"
    }
    
    class func attributedStringFromString(string: String) -> NSAttributedString {
        return NSAttributedString(
            data: string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!,
            options: [
                NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType,
                NSCharacterEncodingDocumentAttribute : NSUTF8StringEncoding
            ],
            documentAttributes: nil,
            error: nil)!
    }
    
    func itemDetails() -> NewsItemDetails {
        return NewsItemDetails(
            id: id,
            text: text,
            attributedText: RLMNewsItemDetails.attributedStringFromString(text)
        )
    }
}

class RLMNewsItemLikeState: RLMObject {
    dynamic var id = ""
    dynamic var liked = false
    dynamic var pending = false
    
    override class func primaryKey() -> String {
        return "id"
    }
    
    func itemLikeState() -> NewsItemLikeState {
        return NewsItemLikeState(
            id: id,
            liked: liked,
            pending: pending
        )
    }
}


// data accessor

class NewsDataModel {
    static let sharedInstance = NewsDataModel()
    
    let httpClient = NewsHttpClent.sharedInstance
    
    
    // fetches
    
    func fetchNewsItems() -> [NewsItem] {
        var items = [NewsItem]()
        for rmlItem in RLMNewsItem.allObjects().sortedResultsUsingProperty("time", ascending: false) {
            if let rmlItem = rmlItem as? RLMNewsItem {
                items.append(rmlItem.item())
            }
        }
        return items
    }
    
    func fetchNewsItemLikeStates() -> [NewsItemLikeState] {
        var likeStates = [NewsItemLikeState]()
        
        for rmlLike in RLMNewsItemLikeState.allObjects() {
            if let rmlLike = rmlLike as? RLMNewsItemLikeState {
                likeStates.append(rmlLike.itemLikeState())
            }
        }
        
        return likeStates
    }
    
    func fetchNewsExtendedItems() -> NewsExtendedItems {
        let items = fetchNewsItems()
        let likeStates = fetchNewsItemLikeStates()
        var likeStatesMap = [String : NewsItemLikeState]()
        
        likeStates.map({ likeState in
            likeStatesMap[likeState.id] = likeState
        })
        
        return NewsExtendedItems(items: items, likeStatesMap: likeStatesMap)
    }
    
    func invertLikeAtItem(#id: String) -> NewsItemLikeState? {
        var newsItemLikeState: NewsItemLikeState?
        
        RLMRealm.defaultRealm().beginWriteTransaction()
        
        if let likeState = fetchRlmItemLikeState(id: id) {
            let liked = !likeState.liked // new liked value
            
            // if new `liked' value differs from old `liked' value
            // then we invert .liked & .pernding values
            
            // Code equivalent to:
            // switch (liked, likeState.liked, likeState.pending) {
            // case (false, true, false):
            //     (likeState.liked, likeState.pending) = (false, true)
            // case (false, true, true):
            //     (likeState.liked, likeState.pending) = (false, false)
            // case (true, false, false):
            //     (likeState.liked, likeState.pending) = (true, true)
            // case (true, false, true):
            //     (likeState.liked, likeState.pending) = (true, false)
            // case _:
            //     break
            // }
            
            if liked != likeState.liked {
                (likeState.liked, likeState.pending) = (!likeState.liked, !likeState.pending)
            }
            
            newsItemLikeState = likeState.itemLikeState()
        } else {
            let likeState = RLMNewsItemLikeState()
            
            likeState.id = id
            likeState.liked = true
            likeState.pending = true
            
            RLMRealm.defaultRealm().addObject(likeState)
            
            newsItemLikeState = likeState.itemLikeState()
        }
        
        RLMRealm.defaultRealm().commitWriteTransaction()
        
        return newsItemLikeState
    }
    
    // requests
    
    func requestFetchedNewsExtendedItems() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            NSNotificationCenter.defaultCenter().postNotificationName(
                newsExtendedItemsFetchedNotification,
                object: self.fetchNewsExtendedItems())
        })
    }
    
    func requestLoadedNewsItems() {
        self.httpClient.getNewsListItems({ itemDicts in
            RLMRealm.defaultRealm().transactionWithBlock {
                itemDicts.map { RLMNewsItem.createOrUpdateInDefaultRealmWithObject($0) }
            }
            
            let items = self.fetchNewsItems()
            
            NSNotificationCenter.defaultCenter().postNotificationName(
                newsItemsLoadedNotification,
                object: items)
        }, failure: { error in
            NSNotificationCenter.defaultCenter().postNotificationName(
                newsItemsLoadErrorNotification,
                object: error)
        })
    }
    
    func updatePendingLike(id: String, newLikeCount: Int?, isLiked: Bool) -> (NewsItem, NewsItemLikeState)? {
        var result: (NewsItem, NewsItemLikeState)?
        RLMRealm.defaultRealm().transactionWithBlock {
            switch (self.fetchRlmItem(id: id), self.fetchRlmItemLikeState(id: id)) {
            case (.Some(let item), .Some(let likeState)):
                if let newLikeCount = newLikeCount {
                    item.like_count = newLikeCount
                } else {
                    item.like_count = item.like_count + (isLiked ? 1 : -1)
                }
                likeState.pending = false
                
                result = (item.item(), likeState.itemLikeState())
            case _:
                break
            }
        }
        return result
    }
    
    func performPendingLikeRequest(likeState: NewsItemLikeState) {
        let httpRequest = likeState.liked
            ? self.httpClient.postNewsItemLike
            : self.httpClient.deleteNewsItemLike
        
        httpRequest(likeState.id, success: { newLikeCount in
            if let (item, itemLikeState) =
                self.updatePendingLike(likeState.id, newLikeCount: newLikeCount, isLiked: likeState.liked) {
                    
                NSNotificationCenter.defaultCenter()
                    .postNotificationName(newsItemFetchedNotification, object: item)
                NSNotificationCenter.defaultCenter()
                    .postNotificationName(newsItemLikeStateFetchedNotification, object: itemLikeState)
                    
            }
        }, failure: { error in
            println("like/unlike \(likeState.id) failure: \(error)")
        })
    }
    
    func requestInvertLikeAtItem(#id: String) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let likeState = self.invertLikeAtItem(id: id)
            
            if let newLikeState = self.fetchRlmItemLikeState(id: id)?.itemLikeState() {
                self.performPendingLikeRequest(newLikeState)
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName(
                newsItemLikeStateFetchedNotification,
                object: likeState)
        })
    }
    
    func requestNewsItemDetails(id: String) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            func fetchRlmItemDetails(id: String) -> RLMNewsItemDetails? {
                return RLMNewsItemDetails.objectsWhere("id = '\(id)'").firstObject() as? RLMNewsItemDetails
            }
            
            if let rlmItemDetails = fetchRlmItemDetails(id) {
                let details = rlmItemDetails.itemDetails()
                
                NSNotificationCenter.defaultCenter().postNotificationName(
                    newsItemDetailsFetchedNotification,
                    object: details)
            } else {
                
                self.httpClient.getNewsItemDetails(id, success: { itemDict in
                    RLMRealm.defaultRealm().transactionWithBlock {
                        RLMNewsItemDetails.createOrUpdateInDefaultRealmWithObject(itemDict)
                    }
                    
                    let rlmItemDetails = fetchRlmItemDetails(id)!
                    let itemDetails = rlmItemDetails.itemDetails()
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        newsItemDetailsFetchedNotification,
                        object: itemDetails)
                }, failure: { error in
                    // self.postNotification(newsItemDetailsLoadErrorNotification, error: error)
                })
            }
        })
    }
    
    
    // realm fetches
    
    func fetchRlmItemLikeState(#id: String) -> RLMNewsItemLikeState? {
        return RLMNewsItemLikeState.objectsWhere("id = '\(id)'").firstObject() as? RLMNewsItemLikeState
    }
    
    func fetchRlmItem(#id: String) -> RLMNewsItem? {
        return RLMNewsItem.objectsWhere("id = '\(id)'").firstObject() as? RLMNewsItem
    }
    
}
