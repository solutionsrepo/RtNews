import Foundation
import Realm

class RLMImageCacheEntry: RLMObject {
    dynamic var remoteUrl = ""
    dynamic var localFileName = ""
    
    override class func primaryKey() -> String {
        return "remoteUrl"
    }
}


class ImageCache {
    let lockQueue = dispatch_queue_create("ru.rtnews.LockQueue", nil)
    
    
    class func realm() -> RLMRealm {
        return RLMRealm(path: cacheDirectoryUrl().URLByAppendingPathComponent("imageCache.realm").path!)
    }
    
    class func cacheDirectoryUrl() -> NSURL {
        return NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] as! String)!
    }
    
    func getLocalUrlByRemoteUrl(url: NSURL) -> NSURL? {
        var localUrl: NSURL?
        
        dispatch_sync(lockQueue) {
            let result = RLMImageCacheEntry.objectsInRealm(ImageCache.realm(), "remoteUrl = '\(url)'")
            if (result.count > 0) {
                localUrl = ImageCache.cacheDirectoryUrl().URLByAppendingPathComponent(result.firstObject().localFileName)
            }
        }
        
        return localUrl
    }
    
    func saveFile(#localUrl: NSURL, forUrl url: NSURL) {
        let randomFileUrl = ImageCache.cacheDirectoryUrl().URLByAppendingPathComponent(NSUUID().UUIDString)
        
        var error: NSError?
        NSFileManager.defaultManager().copyItemAtURL(localUrl, toURL: randomFileUrl, error: &error)
        
        dispatch_sync(lockQueue) {
            let entry = RLMImageCacheEntry();
            
            entry.remoteUrl = url.absoluteString!
            entry.localFileName = randomFileUrl.lastPathComponent!
            
            let r = ImageCache.realm()
            
            r.transactionWithBlock {
                r.addObject(entry)
            }
        }
    }
}
