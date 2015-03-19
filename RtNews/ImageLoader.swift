import UIKit

class ImageLoader {
    static let sharedInstance = ImageLoader()
    
    var views: [NSURL: UIImageView] = [:]
    
    let cache = ImageCache()
    
    var tasks: [NSURL: NSURLSessionDownloadTask] = [:]
    let tasksMapSem = dispatch_semaphore_create(1);
    
    func saveWeakRefToImageView(imageView: UIImageView, _ url: NSURL) {
        weak var v = imageView
        views[url] = v
    }
    
    func imageFromLocalUrl(url: NSURL) -> UIImage? {
        switch NSData(contentsOfURL: url) {
        case .Some(let data): return UIImage(data: data)
        case _: return .None
        }
    }
    
    func downloadWithRequest(request: NSURLRequest) -> NSURL? {
        let sem = dispatch_semaphore_create(0);
        
        var localUrl: NSURL?
        
        let task =
        NSURLSession.sharedSession().downloadTaskWithRequest(request, completionHandler: { (url, _, error) in
            dispatch_semaphore_wait(self.tasksMapSem, DISPATCH_TIME_FOREVER);
            self.tasks.removeValueForKey(request.URL!)
            dispatch_semaphore_signal(self.tasksMapSem);
            
            localUrl = url
            
            dispatch_semaphore_signal(sem);
        })
        
        dispatch_semaphore_wait(self.tasksMapSem, DISPATCH_TIME_FOREVER);
        tasks[request.URL!] = task;
        dispatch_semaphore_signal(self.tasksMapSem);
        
        task.resume()
    
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        
        return localUrl
    }
    
    func assignImage(imageView: UIImageView, _ url: NSURL) {
        func aquireLocalUrl() -> NSURL? {
            switch cache.getLocalUrlByRemoteUrl(url) {
            case .Some(let localUrl):
                return localUrl
            case _:
                let request = NSURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 60)
                let localUrl = downloadWithRequest(request)
                
                if let localUrl = localUrl {
                    cache.saveFile(localUrl: localUrl, forUrl: url)
                }
                
                return localUrl
            }
        }
        
        if let localUrl = aquireLocalUrl() {
            if let image = self.imageFromLocalUrl(localUrl) {
                dispatch_async(dispatch_get_main_queue(), {
                    imageView.image = image
                })
            }
        }
    }
    
    func deferredAssignImage(imageView: UIImageView, withUrl url: NSURL) {
        imageView.image = .None
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.assignImage(imageView, url)
        })
    }
}
