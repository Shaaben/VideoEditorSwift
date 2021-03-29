//
//  WatermarkVideoViewController.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import UIKit
import AVFoundation
import PKHUD
import Gallery

class WatermarkVideoViewController: UIViewController {

    //MARK:- Outlets

    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var convertBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet var chooseImageBtn: UIButton!
    @IBOutlet var selectPositionBtn: UIButton!
    @IBOutlet var watermarkImageView: UIImageView!
    @IBOutlet var selectedPositionLabel: UILabel!
    @IBOutlet var topLeftBtn: UIButton!
    @IBOutlet var topRightBtn: UIButton!
    @IBOutlet var bottomLeftBtn: UIButton!
    @IBOutlet var bottomRightBtn: UIButton!
    @IBOutlet var selectPositionMainView: UIView!
    @IBOutlet var selectPositionSubView: GradientView!
    @IBOutlet var noImageSelectedLabel: UILabel!
    @IBOutlet var watermarkControlsView: UIView!

    //MARK:- Vars and Objects
    
    var currentFeature:AppFeatures!
    var objVideoAsset:AVAsset!
    var player: AVPlayer?
    var objDestinationURL:URL!
    var screenTitle: String?
    var position:QUWatermarkPosition = .TopRight
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = screenTitle
        
        convertBtn.backgroundColor = BtnLayout.btnColor
        convertBtn.layer.cornerRadius = BtnLayout.btnRadius
        convertBtn.layer.borderWidth = BtnLayout.btnBorderWidth
        convertBtn.layer.borderColor = BtnLayout.btnBorderColor
        
        selectPositionBtn.backgroundColor = BtnLayout.btnColor_2
        selectPositionBtn.layer.cornerRadius = BtnLayout.btnRadius
        selectPositionBtn.layer.borderWidth = BtnLayout.btnBorderWidth
        selectPositionBtn.layer.borderColor = UIColor.darkGray.cgColor
        selectPositionBtn.titleLabel?.font = UIFont(name: "SairaSemiCondensed-Regular", size: 16)
        
        chooseImageBtn.backgroundColor = BtnLayout.btnColor_2
        chooseImageBtn.layer.cornerRadius = BtnLayout.btnRadius
        chooseImageBtn.layer.borderWidth = BtnLayout.btnBorderWidth
        chooseImageBtn.layer.borderColor = UIColor.darkGray.cgColor
        chooseImageBtn.titleLabel?.font = UIFont(name: "SairaSemiCondensed-Regular", size: 16)
        
        watermarkImageView.backgroundColor = BtnLayout.btnColor_2
        watermarkImageView.layer.cornerRadius = BtnLayout.btnRadius
        watermarkImageView.layer.borderWidth = BtnLayout.btnBorderWidth
        watermarkImageView.layer.borderColor = UIColor.darkGray.cgColor
        noImageSelectedLabel.font = UIFont(name: "SairaSemiCondensed-Regular", size: 10)
        //          watermarkImageView.titleLabel?.font = UIFont(name: "SairaSemiCondensed-Regular", size: 16)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
            self.loadAsset(self.objVideoAsset)
        }
    }

    @IBAction func closeAction(_ sender: Any) {
    navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        loadInterstitialAd()
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

    func watermarkVideo(asset:AVAsset){
        HUD.show(.systemActivity)
        VideoUtility.shared.watermark(video: asset, startTime: CMTime.zero, duration: asset.duration, watermarkText: nil, watermarkImage: watermarkImageView.image, watermarkPosition: position) { (result) in
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
                    self.convertBtn.isSelected = true
                    self.convertBtn.setTitle("Save to Photos", for: .selected)
                    self.watermarkControlsView.isHidden = true
                    self.objDestinationURL = videoURL
                    self.loadAsset(AVAsset(url: videoURL))
                    self.showPlayButton(true)
                }
                break
            }
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
    
    func showGalleryView(){
        Config.tabsToShow = [.imageTab]
        Config.Camera.imageLimit = 1
        let gallery = GalleryController()
        gallery.delegate = self
        present(gallery, animated: true, completion: nil)
    }

    func showViewPosition(){
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        selectPositionMainView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        UIView.animate(withDuration: 0.3, delay: 0, options: [], animations: {
            self.selectPositionMainView.transform = CGAffineTransform.identity
            self.selectPositionMainView.isHidden = false
        }) { (finished) in
            self.selectPositionMainView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        }
    }
    
    func hideViewPosition(){
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.selectPositionMainView.isHidden = true
        self.selectPositionMainView.backgroundColor = UIColor.clear
    }
//
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
        if self.convertBtn.isSelected {
            HUD.show(.systemActivity)
            UISaveVideoAtPathToSavedPhotosAlbum(self.objDestinationURL.path, self, #selector(WatermarkVideoViewController.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
            HUD.hide()
        }else{
            if watermarkImageView.image != nil {
                HUD.show(.systemActivity)
                self.watermarkVideo(asset: objVideoAsset)
            }else{
                showAlert(message: "Select an image to be watermarked on video.", buttonClicked: nil)
            }
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
    
    //MARK:- Position Button Action Methods
    @IBAction func onPressChooseImage(_ sender: UIButton) {
        showGalleryView()
    }
    
    @IBAction func onPressSelectPosition(_ sender: UIButton) {
        showViewPosition()
    }
    
    @IBAction func onPressCloseViewPosition(_ sender: UIButton) {
        hideViewPosition()
    }
    
    @IBAction func onPressTopLeft(_ sender: UIButton) {
        selectedPositionLabel.text = sender.titleLabel?.text
        position = .TopLeft
        hideViewPosition()
    }
    
    @IBAction func onPressTopRight(_ sender: UIButton) {
        selectedPositionLabel.text = sender.titleLabel?.text
        position = .TopRight
        hideViewPosition()
    }
    
    @IBAction func onPressBottomLeft(_ sender: UIButton) {
        selectedPositionLabel.text = sender.titleLabel?.text
        position = .BottomLeft
        hideViewPosition()
    }
    
    @IBAction func onPressBottomRight(_ sender: UIButton) {
        selectedPositionLabel.text = sender.titleLabel?.text
        position = .BottomRight
        hideViewPosition()
    }
}

extension WatermarkVideoViewController: GalleryControllerDelegate{
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        controller.dismiss(animated: true, completion: nil)
        for imageAsset in images{
            imageAsset.resolve { (image) in
                self.watermarkImageView.image = image
                self.noImageSelectedLabel.isHidden = true
            }
        }
    }
    
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        
    }
    
    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
    }
    
    func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
