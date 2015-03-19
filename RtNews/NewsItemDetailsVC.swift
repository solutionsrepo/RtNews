import UIKit

class NewsItemDetailsVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let dataModel = NewsDataModel.sharedInstance
    let data = NewsViewData.sharedInstance
    
    
    
    func checkCurrentLikeState() {
        if let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: data.selectedItemIndex, inSection: 0)) as? NewsItemDetailsCell {
            let item = data.items[data.selectedItemIndex]
            let likeState = data.likeStatesMap[item.id]
            let liked = likeState?.liked == .Some(true)
            
            self.navigationItem.rightBarButtonItem?.title = liked ? "Unlike" : "Like"
            cell.setLikeState(likeCount: item.like_count, likeState: likeState)
        }
    }
    
    func checkCurrentPage() {
        if let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: data.selectedItemIndex, inSection: 0)) as? NewsItemDetailsCell {
            let item = data.items[data.selectedItemIndex]
            
            checkCurrentLikeState()
            
            if let details = data.detailsMap[item.id] {
                cell.setDetails(details)
            }
        }
    }
    
    
    // events
    
    @objc
    func newsItemDetailsFetched() {
        checkCurrentPage()
    }
    
    @objc
    func newsItemLikeStateFetched() {
        checkCurrentLikeState()
    }
    
    @IBAction func likeBtnTapped() {
        let id = data.items[data.selectedItemIndex].id
        
        dataModel.requestInvertLikeAtItem(id: id)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        func registerNotification(selector: Selector, name: String) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: selector, name: name, object: .None)
        }
        
        registerNotification("newsItemDetailsFetched", newsItemDetailsFetchedToDataNotification)
        registerNotification("newsItemLikeStateFetched", newsItemLikeStateFetchedToDataNotification)
        
        
        self.edgesForExtendedLayout = .None
        self.collectionView?.pagingEnabled = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        reload()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        checkCurrentLikeState()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        collectionView.collectionViewLayout.invalidateLayout()
        
        reload()
    }
    
    
    func reload() {
        UIView.animateWithDuration(0, animations: {
        }, completion: { _ in
            self.collectionView.reloadData()
            self.scrollToSelectedItem()
        })
    }
    
    func scrollToSelectedItem() {
        self.collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: data.selectedItemIndex, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false)
    }
    
    
    // collection view data

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.items.count;
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("detailsCell", forIndexPath: indexPath) as! NewsItemDetailsCell
        
        let item = data.items[indexPath.row]
        let likeState = data.likeStatesMap[item.id]
        
        cell.setItem(item)
        cell.setLikeState(likeCount: item.like_count, likeState: likeState)
        
        cell.scrollContentToTop()
        
        if let details = data.detailsMap[item.id] {
            cell.setDetails(details)
        } else {
            cell.clearDetails()
            self.dataModel.requestNewsItemDetails(item.id)
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        data.selectedItemIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        checkCurrentPage()
    }
}

