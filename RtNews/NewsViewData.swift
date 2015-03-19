import Foundation


let newsItemsReloadedToDataNotification = "newsItemsReloadedToDataNotification"
let newsItemsReloadErrorNotification = "newsItemsReloadErrorNotification"

let newsExtendedItemsFetchedToDataNotification = "newsExtendedItemsFetchedToDataNotification"
let newsItemDetailsFetchedToDataNotification = "newsItemDetailsFetchedToDataNotification"
let newsItemLikeStateFetchedToDataNotification = "newsItemLikeStateFetchedToDataNotification"

let newsItemFetchedToDataNotification = "newsItemFetchedToDataNotification"


class NewsExtendedItems {
    let items: [NewsItem]
    let likeStatesMap: [String : NewsItemLikeState]
    
    init(items: [NewsItem], likeStatesMap: [String : NewsItemLikeState]) {
        self.items = items
        self.likeStatesMap = likeStatesMap
    }
}


class NewsViewData {
    static let sharedInstance = NewsViewData()

    var items: [NewsItem] = []
    var detailsMap: [String : NewsItemDetails] = [:]
    var likeStatesMap: [String : NewsItemLikeState] = [:]
    var selectedItemIndex: Int = 0
    
    init() {
        func registerNotification(selector: Selector, name: String) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: selector, name: name, object: .None)
        }
        
        registerNotification("newsItemsLoaded:", newsItemsLoadedNotification)
        registerNotification("newsItemsLoadError:", newsItemsLoadErrorNotification)
        
        registerNotification("newsExtendedItemsFetched:", newsExtendedItemsFetchedNotification)
        registerNotification("newsItemDetailsFetched:", newsItemDetailsFetchedNotification)
        registerNotification("newsItemLikeStateFetched:", newsItemLikeStateFetchedNotification)
        
        registerNotification("newsItemFetched:", newsItemFetchedNotification)
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    func postNotification(name: String) {
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: nil)
    }
    
    
    
    @objc
    func newsItemsLoaded(n: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {
            self.items = n.object as! [NewsItem]
            
            self.postNotification(newsItemsReloadedToDataNotification)
        })
    }
    
    @objc
    func newsItemsLoadError(n: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {
            let error = n.object as! NSError
            
            NSNotificationCenter.defaultCenter().postNotificationName(newsItemsReloadErrorNotification, object: error)
        })
    }
    
    @objc
    func newsExtendedItemsFetched(n: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {
            let extendedItems = n.object as! NewsExtendedItems
            
            self.items = extendedItems.items
            self.likeStatesMap = extendedItems.likeStatesMap
            
            self.postNotification(newsExtendedItemsFetchedToDataNotification)
        })
    }
    
    @objc
    func newsItemDetailsFetched(n: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {
            let details = n.object as! NewsItemDetails
            self.detailsMap[details.id] = details
            
            self.postNotification(newsItemDetailsFetchedToDataNotification)
        })
    }
    
    @objc
    func newsItemLikeStateFetched(n: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {
            let likeState = n.object as! NewsItemLikeState
            self.likeStatesMap[likeState.id] = likeState
            
            self.postNotification(newsItemLikeStateFetchedToDataNotification)
        })
    }
    
    @objc
    func newsItemFetched(n: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {
            let newItem = n.object as! NewsItem
            
            let existingIndex: Int? = {
                for (i, item) in enumerate(self.items) {
                    if item.id == newItem.id {
                        return .Some(i)
                    }
                }
                return .None
            }()
            
            if let index = existingIndex {
                self.items.removeAtIndex(index)
                self.items.insert(newItem, atIndex: index)
            }
            
            self.postNotification(newsItemFetchedToDataNotification)
        })
    }
}
