
//
//  VUVideoFilterVC.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import UIKit
import AVFoundation
import PKHUD

class VUVideoFilterVC: UIViewController {

    //MARK:- Outlets
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var convertBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filtersView: UIView!
    
    //MARK:- Vars and Objects
    
    var currentFeature:AppFeatures!
    var objVideoAsset:AVAsset!
    var player: AVPlayer?
    var objDestinationURL:URL!
    var screenTitle: String?
    var arrFiltersList:[VideoFilterModel] = []
    var smallImage: UIImage?
    var filterIndex = 0
    var videoComposition: AVMutableVideoComposition!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = screenTitle
        
        convertBtn.backgroundColor = BtnLayout.btnColor
               convertBtn.layer.cornerRadius = BtnLayout.btnRadius
               convertBtn.layer.borderWidth = BtnLayout.btnBorderWidth
               convertBtn.layer.borderColor = BtnLayout.btnBorderColor
        
        

        DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
            self.loadAsset(self.objVideoAsset)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        loadInterstitialAd()
    }

    @IBAction func closebtnAction(_ sender: Any) {
      navigationController?.popViewController(animated: true)
    }
    //MARK:- Other Methods
    
    func loadAsset(_ asset: AVAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        let layer: AVPlayerLayer = AVPlayerLayer(player: player)
        layer.backgroundColor = UIColor.clear.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: playerView.frame.height)
        layer.videoGravity = AVLayerVideoGravity.resizeAspect
        playerView.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        playerView.layer.addSublayer(layer)
        smallImage = VideoUtility.shared.getThumbnailImage(asset: objVideoAsset)
        loadFiltersList()
        applyFilter(atIndex: 0)
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

    func loadFiltersList(){
        
        if let path = Bundle.main.url(forResource: "Filters", withExtension: "plist"){
            if let plistArray = NSArray(contentsOf: path) as? [[String:AnyHashable]] {
                for obj in plistArray{
                    let model = VideoFilterModel.init(dict: obj)
                    arrFiltersList.append(model)
                }
                collectionView.reloadData()
            }
        }
    }
    
    func applyFilter(atIndex index:Int){
        let avPlayerItem = AVPlayerItem(asset: objVideoAsset)
        if(index != 0){
            videoComposition = AVMutableVideoComposition(asset: objVideoAsset, applyingCIFiltersWithHandler: { (request) in
                let source = request.sourceImage.clampedToExtent()
                let filterName = self.arrFiltersList[index].filterName
                let filter = CIFilter(name:filterName)!
                filter.setDefaults()
                filter.setValue(source, forKey: kCIInputImageKey)
                let output = filter.outputImage!
                request.finish(with:output, context: nil)
            })
            avPlayerItem.videoComposition = videoComposition
        }
        NotificationCenter.default.addObserver(self, selector: #selector(SlowFastVideoViewController.itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avPlayerItem)
        player!.replaceCurrentItem(with: avPlayerItem)
    }
    
    func scrollCollectionViewToIndex(itemIndex: Int) {
        let indexPath = IndexPath(item: itemIndex, section: 0)
        self.collectionView?.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    func filterVideo(asset:AVAsset){
        onPressPauseVideo(nil)
        VideoUtility.shared.filterVideo(asset, startTime: CMTime.zero, duration: objVideoAsset.duration, videoComposition: (player?.currentItem?.videoComposition)) { (result) in
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
                    self.filtersView.isHidden = true
                    self.convertBtn.isSelected = true
                    self.convertBtn.setTitle("Save to Photos", for: .selected)
                }
                break
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
        HUD.show(.systemActivity)
        if self.convertBtn.isSelected {
            HUD.show(.systemActivity)
            UISaveVideoAtPathToSavedPhotosAlbum(self.objDestinationURL.path, self, #selector(VUVideoFilterVC.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
            HUD.hide()
        }else{
            self.filterVideo(asset: objVideoAsset)
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
}

extension VUVideoFilterVC: UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrFiltersList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoFilterCell", for: indexPath) as! VideoFilterCell
        var filteredImage = smallImage
        if indexPath.row != 0 {
            filteredImage = VideoUtility.shared.createFilteredImage(filterName: arrFiltersList[indexPath.row].filterName, image: smallImage!)
        }
        cell.imageView.image = filteredImage
        cell.setUpCell(model: arrFiltersList[indexPath.row])
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        arrFiltersList[filterIndex].isSelected = false
        collectionView.reloadItems(at: [IndexPath(item: filterIndex, section: 0)])
        filterIndex = indexPath.row
        arrFiltersList[filterIndex].isSelected = true
        applyFilter(atIndex: filterIndex)
        collectionView.reloadItems(at: [IndexPath(item: filterIndex, section: 0)])
        scrollCollectionViewToIndex(itemIndex: indexPath.item)
    }
}
