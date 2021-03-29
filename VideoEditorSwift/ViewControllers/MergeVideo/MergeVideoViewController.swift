//
//  MergeVideoViewController.swift
//  
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import UIKit
import AVFoundation
import PKHUD
import AssetsPickerViewController
import Photos

class MergeVideoViewController: UIViewController {

    //MARK:- Outlets
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var convertBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var viewSelectedVideos: UIView!
    @IBOutlet weak var segmentVideoQuality: UISegmentedControl!

    //MARK:- Vars and Objects
    
    var currentFeature:AppFeatures!
    var objVideoAsset:AVAsset!
    var player: AVPlayer!
    var objDestinationURL:URL!
    var screenTitle: String?
    var arrFiltersList:[VideoFilterModel] = []
    var smallImage: UIImage?
    var filterIndex = 0
    var videoComposition: AVMutableComposition!
    var arrSelectedVideosList:[AVAsset] = []
    var longPressGesture: UILongPressGestureRecognizer!
    var videoQuality:VideoQuality = VideoQuality.AVAssetExportPresetMediumQuality

    var originalIndexPath: IndexPath?
    var draggingIndexPath: IndexPath?
    var draggingView: UIView?
    var dragOffset = CGPoint.zero

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = screenTitle
             convertBtn.backgroundColor = BtnLayout.btnColor
              convertBtn.layer.cornerRadius = BtnLayout.btnRadius
              convertBtn.layer.borderWidth = BtnLayout.btnBorderWidth
              convertBtn.layer.borderColor = BtnLayout.btnBorderColor

        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(longPress:)))
        collectionView.addGestureRecognizer(longPressGesture)

        segmentVideoQuality.selectedSegmentIndex = 1
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
            self.loadAsset(asset: self.arrSelectedVideosList.first!)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction func closeAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    //MARK:- Other Methods
    func loadAsset(asset:AVAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        NotificationCenter.default.addObserver(self, selector: #selector(self.itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        if self.player == nil{
            self.player = AVPlayer(playerItem: playerItem)
            let layer: AVPlayerLayer = AVPlayerLayer(player: self.player)
            layer.backgroundColor = UIColor.clear.cgColor
            layer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.playerView.frame.height)
            layer.videoGravity = AVLayerVideoGravity.resizeAspect
            self.playerView.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
            self.playerView.layer.addSublayer(layer)
        }else{
            self.player?.replaceCurrentItem(with: playerItem)
        }
    }
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        player?.seek(to: CMTime.zero)
        self.showPlayButton(true)
    }
    
    func showPlayButton(_ isPlayVisible:Bool){
        if isPlayVisible {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .allowUserInteraction, animations: {
                self.pauseBtn.alpha = 0.0
                self.pauseBtn.layoutIfNeeded()
            }, completion: { (complete) in
                self.playBtn.alpha = 1.0
                self.playBtn.layoutIfNeeded()
            })
        }else{
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .allowUserInteraction, animations: {
                self.playBtn.alpha = 0.0
                self.playBtn.layoutIfNeeded()
            }, completion: { (complete) in
                self.pauseBtn.alpha = 1.0
                self.pauseBtn.layoutIfNeeded()
            })
        }
    }
    
    @objc func video(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject)
    {
        if let _ = error {
            showAlert(message: "Error,Video failed to save.", buttonClicked: nil)
        }else{
            showAlert(message: "Video successfully saved.") { (action) in
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
   
    func mergeVideos(){
        if arrSelectedVideosList.count == 0{
            showAlert(message: "Please select a video.", buttonClicked: nil)
            return
        }else if arrSelectedVideosList.count == 1{
            showAlert(message: "Please select more than one video.", buttonClicked: nil)
            return
        }else{
            HUD.show(.systemActivity)
            VideoUtility.shared.mergeVideoComposition(arrayVideos: arrSelectedVideosList, videoQuality: videoQuality) { (result) in
                switch result{
                case .Error(let strError):
                    DispatchQueue.main.async {
                        HUD.hide()
                        showAlert(message: strError, buttonClicked: nil)
                    }
                    break
                case .Success(let videoURL):
                    DispatchQueue.main.async {
                        HUD.hide()
                        self.objDestinationURL = videoURL
                        self.loadAsset(asset: AVAsset(url: self.objDestinationURL))
                        self.viewSelectedVideos.isHidden = true
                        self.convertBtn.isSelected = true
                        self.convertBtn.setTitle("Save to Photos", for: .selected)
                    }
                    break
                }
            }
        }
    }
    
//    func loadBannerAd(){
//        //GADMobileAds.configure(withApplicationID: Admob.appId)
//        viewBannerAd.delegate = self
//        viewBannerAd.adUnitID = GoogleAdsUnitID.Live.strBannerAdsID
//        viewBannerAd.rootViewController = self
//        //let request = GADRequest()
//        //request.testDevices = [ kGADSimulatorID ] // Sample device ID
//        self.viewBannerAd.load(GADRequest())
//    }
//
//    func loadInterstitialAd(){
//        totalScreenTraverse += 1
//        if (totalScreenTraverse == maxScreenTraverse){
//            totalScreenTraverse = 0
//            interstitial = GADInterstitial(adUnitID: GoogleAdsUnitID.Live.strInterstitialAdsID)
//            interstitial.delegate = self
//            //let request = GADRequest()
//            //request.testDevices = [kGADSimulatorID,"cee617e9ce777dd4fedff44fa3704fed"]
//            interstitial.load(GADRequest())
//            if interstitial.isReady {
//                interstitial.present(fromRootViewController: self)
//            } else {
//                print("Ad wasn't ready")
//            }
//        }
//    }

    //MARK:- Button Action Methods
    
    @IBAction func onPressConvertVideo(_ sender: UIButton) {
        if convertBtn.isSelected{
            HUD.show(.systemActivity)
            UISaveVideoAtPathToSavedPhotosAlbum(self.objDestinationURL.path, self, #selector(MergeVideoViewController.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
            HUD.hide()
        }else{
            mergeVideos()
        }
    }
    
    @IBAction func onPressPlayVideo(_ sender: UIButton?) {
        guard let player = player else { return }
        player.play()
        self.showPlayButton(false)
    }
    
    @IBAction func onPressPauseVideo(_ sender: UIButton?) {
        guard let player = player else { return }
        player.pause()
        self.showPlayButton(true)
    }

    
    @IBAction func onPressSegmentValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            videoQuality = VideoQuality.AVAssetExportPresetLowQuality
        case 1:
            videoQuality = VideoQuality.AVAssetExportPresetMediumQuality
        case 2:
            videoQuality = VideoQuality.AVAssetExportPresetHighestQuality
        default:
            videoQuality = VideoQuality.AVAssetExportPresetMediumQuality
        }
    }
    
    //MARK:- CollectionView Cell Drag and Drop Handler Method
    
    @objc func handleLongGesture(longPress: UILongPressGestureRecognizer) {
        let location = longPress.location(in: collectionView!)
        switch(longPress.state) {
        case .began: startDragAtLocation(location: location)
        case .changed: updateDragAtLocation(location: location)
        case .ended: endDragAtLocation(location: location)
        default:
            collectionView.cancelInteractiveMovement()
        }
    }

    func startDragAtLocation(location: CGPoint) {
        guard let cv = collectionView else { return }
        guard let indexPath = cv.indexPathForItem(at: location) else { return }
        guard cv.dataSource?.collectionView!(cv, canMoveItemAt: indexPath) == true else { return }
        guard let cell = cv.cellForItem(at: indexPath) else { return }
        
        originalIndexPath = indexPath
        draggingIndexPath = indexPath
        draggingView = cell.snapshotView(afterScreenUpdates: true)
        draggingView!.frame = cell.frame
        cv.addSubview(draggingView!)
        
        dragOffset = CGPoint(x: draggingView!.center.x - location.x, y: draggingView!.center.y - location.y)
        
        draggingView?.layer.shadowPath = UIBezierPath(rect: draggingView!.bounds).cgPath
        draggingView?.layer.shadowColor = UIColor.black.cgColor
        draggingView?.layer.shadowOpacity = 0.8
        draggingView?.layer.shadowRadius = 10
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: [], animations: {
            self.draggingView?.alpha = 0.95
            self.draggingView?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: nil)
    }

    func updateDragAtLocation(location: CGPoint) {
        guard let view = draggingView else { return }
        guard let cv = collectionView else { return }

        view.center = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)
        
        if let newIndexPath = cv.indexPathForItem(at: location) {
            cv.moveItem(at: draggingIndexPath!, to: newIndexPath)
            draggingIndexPath = newIndexPath
        }
    }

    func endDragAtLocation(location: CGPoint) {
        guard let dragView = draggingView else { return }
        guard let indexPath = draggingIndexPath else { return }
        guard let cv = collectionView else { return }
        guard let datasource = cv.dataSource else { return }
        
        let targetCenter = datasource.collectionView(cv, cellForItemAt: indexPath).center
        
        let shadowFade = CABasicAnimation(keyPath: "shadowOpacity")
        shadowFade.fromValue = 0.8
        shadowFade.toValue = 0
        shadowFade.duration = 0.4
        dragView.layer.add(shadowFade, forKey: "shadowFade")
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: [], animations: {
            dragView.center = targetCenter
            dragView.transform = CGAffineTransform.identity
            
        }) { (completed) in
            
            if indexPath != self.originalIndexPath! {
                datasource.collectionView!(cv, moveItemAt: self.originalIndexPath!, to: indexPath)
            }
            
            dragView.removeFromSuperview()
            self.draggingIndexPath = nil
            self.draggingView = nil
        }
    }
}

extension MergeVideoViewController: UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  arrSelectedVideosList.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (arrSelectedVideosList.count) == indexPath.row{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MergeVideoAddVideoCell", for: indexPath) as! MergeVideoAddVideoCell
            cell.delegate = self
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MergeVideoCell", for: indexPath) as! MergeVideoCell
            cell.indexPath = indexPath
            let thumbImage = VideoUtility.shared.getThumbnailImage(asset: arrSelectedVideosList[indexPath.row])
            cell.imageView.image = thumbImage
            cell.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        loadAsset(asset: arrSelectedVideosList[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if (arrSelectedVideosList.count) == indexPath.row{
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        if (arrSelectedVideosList.count) == destinationIndexPath.row{
            collectionView.reloadData()
        }else{
            self.player?.pause()
            let temp = arrSelectedVideosList.remove(at: sourceIndexPath.item)
            arrSelectedVideosList.insert(temp, at: destinationIndexPath.item)
            loadAsset(asset: arrSelectedVideosList[destinationIndexPath.item])
        }
    }
}

extension MergeVideoViewController: MergeVideoCellDelegate,MergeVideoAddVideoCellDelegate{
    
    func removeVideo(indexPath: IndexPath) {
        let playerItem = AVPlayerItem(asset: arrSelectedVideosList[indexPath.row])
        if playerItem == self.player?.currentItem{
            self.player?.pause()
        }
        arrSelectedVideosList.remove(at: indexPath.row)
        collectionView.reloadData()
        if arrSelectedVideosList.count>0{
            loadAsset(asset: arrSelectedVideosList.first!)
        }else{
            self.player = nil
            self.playerView.layer.sublayers = nil
        }
    }
    
    func addVideo() {
        if arrSelectedVideosList.count == maxVideoSelection {
            showAlert(message: "You have selected maximum number of videos.", buttonClicked: nil)
            return
        }
        let pickerConfig = AssetsPickerConfig()
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "duration", ascending: true)]
        pickerConfig.assetFetchOptions = [
            .smartAlbum: options,
            .album: options
        ]
        let picker = AssetsPickerViewController()
        picker.pickerConfig = pickerConfig
        picker.pickerDelegate = self
        present(picker, animated: true, completion: nil)
    }
}

extension MergeVideoViewController: AssetsPickerViewControllerDelegate {
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
        self.player?.pause()
        let videoOptions = PHVideoRequestOptions()
        videoOptions.isNetworkAccessAllowed = true
        var counter : Int = 0
        for asset in assets{
            PHImageManager.default().requestAVAsset(forVideo: asset, options: videoOptions) { avAsset, _, _ in
                if let finalAsset = avAsset{
                    self.arrSelectedVideosList.append(finalAsset)
                    if counter == (assets.count - 1){
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                            self.loadAsset(asset: self.arrSelectedVideosList.first!)
                        }
                    }
                    counter = counter + 1
                }
            }
        }
    }
    
    func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        if (controller.selectedAssets.count == (maxVideoSelection-arrSelectedVideosList.count)){
            return false
        }else{
            return true
        }
    }
}
