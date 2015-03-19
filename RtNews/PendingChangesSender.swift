import Foundation


class PendingChangesSender {
    let dataModel = NewsDataModel.sharedInstance
    
    func sendPendingChanges() {
        let likeStates = dataModel.fetchNewsItemLikeStates()
        
        likeStates.map({ likeState -> Void in
            if likeState.pending {
                self.dataModel.performPendingLikeRequest(likeState)
            }
        })
    }
}
