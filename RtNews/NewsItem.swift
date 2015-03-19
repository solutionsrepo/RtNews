import Foundation


class NewsItem : Printable {
    let id: String
    let title: String
    let time: NSDate
    let image: String
    let url: String
    let like_count: Int
    let summary: String
    
    init(id: String, title: String, time: NSDate, image: String, url: String, like_count: Int, summary: String) {
        self.id = id
        self.title = title
        self.time = time
        self.image = image
        self.url = url
        self.like_count = like_count
        self.summary = summary
    }
    
    var description: String {
        return "<NewsItem id: \(id), title: \(title), time: \(time), image: \(image), url: \(url), like_count: \(like_count), summary: \(summary)>"
    }
}

class NewsItemDetails : Printable {
    let id: String
    let text: String?
    let attributedText: NSAttributedString?
    
    init(id: String, text: String?, attributedText: NSAttributedString?) {
        self.id = id
        self.text = text
        self.attributedText = attributedText
    }
    
    var description: String {
        return "<NewsItemDetails id: \(id), text: \(text)>"
    }
}

class NewsItemLikeState : Printable {
    let id: String
    let liked: Bool
    let pending: Bool
    
    init(id: String, liked: Bool, pending: Bool) {
        self.id = id
        self.liked = liked
        self.pending = pending
    }
    
    func likeFix() -> Int {
        if pending {
            return liked ? 1 : -1
        } else {
            return 0
        }
    }

    var description: String {
        return "<NewsItemLikeState id: \(id), liked: \(liked), pending: \(pending)>"
    }
}
