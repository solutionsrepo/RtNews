import UIKit

class NewsListVC: UITableViewController {

    let dataModel = NewsDataModel.sharedInstance
    let data = NewsViewData.sharedInstance

    // Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func registerNotification(selector: Selector, name: String) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: selector, name: name, object: .None)
        }
        
        registerNotification("newsItemsReloaded", newsItemsReloadedToDataNotification)
        registerNotification("newsItemsReloadError:", newsItemsReloadErrorNotification)
        registerNotification("newsExtendedItemsFetched", newsExtendedItemsFetchedToDataNotification)
        registerNotification("newsItemFetched", newsItemFetchedToDataNotification)
        
        
        refreshControl = UIRefreshControl()
        refreshControl?.attributedTitle = NSAttributedString(string: "Updating...")
        refreshControl?.addTarget(self, action: "refreshPoked:", forControlEvents: .ValueChanged)
        refreshControl?.beginRefreshing()
        refreshControl?.endRefreshing()
        
        dataModel.requestFetchedNewsExtendedItems()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    // Events
    
    func newsItemsReloaded() {
        tableView.reloadData()
        refreshControl?.endRefreshing()
    }
    
    func newsItemsReloadError(n: NSNotification) {
        // tableView.reloadData()
        UIAlertView(
            title: "Update error",
            message: (n.object as! NSError).localizedDescription,
            delegate: .None,
            cancelButtonTitle: "OK").show()
        refreshControl?.endRefreshing()
    }
    
    func newsExtendedItemsFetched() {
        tableView.reloadData()
    }
    
    func newsItemFetched() {
        tableView.reloadData()
    }
    
    func refreshPoked(sender: AnyObject) {
        dataModel.requestLoadedNewsItems()
    }
    
    // Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier, self.tableView.indexPathForSelectedRow()) {
        case (.Some("showDetail"), .Some(let indexPath)):
            data.selectedItemIndex = indexPath.row
        case _:
            return
        }
    }

    // Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.items.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NewsListCell", forIndexPath: indexPath) as! NewsListCell
        
        let item = data.items[indexPath.row]
        
        cell.setItem(item, likeState: data.likeStatesMap[item.id])
        
        return cell
    }
}

