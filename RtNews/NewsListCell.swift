import UIKit

class NewsListCell: UITableViewCell {
    
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    
    func setItem(item: NewsItem, likeState: NewsItemLikeState?) {
        if let url = NSURL(string: item.image) {
            ImageLoader.sharedInstance.deferredAssignImage(thumbImageView, withUrl: url)
        }
        
        titleLabel.text = item.title
        summaryLabel.text = item.summary
        timestampLabel.text = formattedStringFromDate(item.time)
        
        let totalLikes = item.like_count + (likeState?.likeFix() ?? 0)
        
        likesLabel.text = totalLikes == 1 ? "\(totalLikes) like" : "\(totalLikes) likes"
    }
}
