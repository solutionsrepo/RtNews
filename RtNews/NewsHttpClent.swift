import Foundation


class NewsHttpClent {
    static let sharedInstance = NewsHttpClent()
    
    let baseUrl = NSURL(string: "http://qt-mobile-apps-dev.appspot.com")!
    // let baseUrl = NSURL(string: "http://localhost:8080")!
    
    enum HttpResponse {
        case Single(NSDictionary)
        case Multiple([NSDictionary])
    }
    
    let invalidResponseFormatError = NSError(
        domain: "NewsHttpClientError",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey : "Invalid response format"])
    

    func httpJsonCommon(url: NSURL, _ httpMethod: String, _ success: (HttpResponse) -> Void, _ failure: (NSError) -> Void) {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = httpMethod
        
        NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, _, error) in
            
            switch error {
            case .None:
                var error: NSError?
                
                switch NSJSONSerialization.JSONObjectWithData(
                    data,
                    options: .MutableContainers | .MutableLeaves | .AllowFragments,
                    error: &error) {
                case .Some(let json) where json is NSDictionary:
                    success(HttpResponse.Single(json as! NSDictionary))
                case .Some(let json) where json is [NSDictionary]:
                    success(HttpResponse.Multiple(json as! [NSDictionary]))
                case _:
                    failure(error!)
                }
            case .Some(let error):
                failure(error)
            }
        }).resume()
    }

    func httpJsonGet(url: NSURL, _ success: (HttpResponse) -> Void, _ failure: (NSError) -> Void) {
        httpJsonCommon(url, "GET", success, failure)
    }

    func httpJsonPost(url: NSURL, _ success: (HttpResponse) -> Void, _ failure: (NSError) -> Void) {
        httpJsonCommon(url, "POST", success, failure)
    }
    
    func httpJsonDelete(url: NSURL, _ success: (HttpResponse) -> Void, _ failure: (NSError) -> Void) {
        httpJsonCommon(url, "DELETE", success, failure)
    }
    
    
    func getNewsListItems(success: ([NSDictionary]) -> Void, failure: (NSError) -> Void) {
        httpJsonGet(
            baseUrl.URLByAppendingPathComponent("articles"),
            { (resonse: HttpResponse) in
                switch resonse {
                case .Multiple(let ds):
                    success(ds)
                case .Single(_):
                    failure(self.invalidResponseFormatError)
                }
            },
            failure)
    }
    
    func getNewsItemDetails(id: String, success: (NSDictionary) -> Void, failure: (NSError) -> Void) {
        httpJsonGet(
            baseUrl.URLByAppendingPathComponent("articles/\(id)"),
            { (resonse: HttpResponse) in
                switch resonse {
                case .Single(let d):
                    success(d)
                case .Multiple(_):
                    failure(self.invalidResponseFormatError)
                }
            },
            failure)
    }
    
    func postNewsItemLike(id: String, success: (Int?) -> Void, failure: (NSError) -> Void) {
        httpJsonPost(
            baseUrl.URLByAppendingPathComponent("articles/\(id)/likes"),
            { (resonse: HttpResponse) in
                switch resonse {
                case .Single(let d):
                    success(d["count "] as? Int)
                case .Multiple(_):
                    failure(self.invalidResponseFormatError)
                }
            },
            failure)
    }
    
    func deleteNewsItemLike(id: String, success: (Int?) -> Void, failure: (NSError) -> Void) {
        httpJsonDelete(
            baseUrl.URLByAppendingPathComponent("articles/\(id)/likes"),
            { (resonse: HttpResponse) in
                switch resonse {
                case .Single(let d):
                    success(d["count "] as? Int)
                case .Multiple(_):
                    failure(self.invalidResponseFormatError)
                }
            },
            failure)
    }
}
