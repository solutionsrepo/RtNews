import UIKit

class NewsItemDetailsCell: UICollectionViewCell {
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    
    func setItem(item: NewsItem) {
        titleLabel.text = item.title
        timeLabel.text = formattedStringFromDate(item.time)
        
        if let url = NSURL(string: item.image) {
            ImageLoader.sharedInstance.deferredAssignImage(self.imageView, withUrl: url)
        }
    }
    
    func setDetails(details: NewsItemDetails) {
        textLabel.attributedText = details.attributedText
    }
    
    func setLikeState(#likeCount: Int, likeState: NewsItemLikeState?) {
        let totalLikes = likeCount + (likeState?.likeFix() ?? 0)
        
        likesLabel.text = totalLikes == 1 ? "\(totalLikes) like" : "\(totalLikes) likes"
    }
    
    func clearDetails() {
        textLabel.attributedText = .None
    }
    
    func scrollContentToTop() {
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentInset.top), animated: false)
    }
}
