
//  Created by Smart Mobile Tech on 28/11/18.

import UIKit
import AVFoundation
import PKHUD

class SlowFastVideoViewController: UIViewController {

    //MARK:- Outlets
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var convertBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet var scaleSpeedLabel: UILabel!
    @IBOutlet var stepper: UIStepper!
    @IBOutlet var videoSpeedControlsView: UIView!
    
    //MARK:- Vars and Objects
    
    var currentFeature:AppFeatures!
    var objVideoAsset:AVAsset!
    var player: AVPlayer?
    var objDestinationURL:URL!
    var scaleFactor:ScaleFactor = .normal
    var speedMode:SpeedoMode = .Slower
    var screenTitle: String?
    
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

    @IBAction func closeAction(_ sender: Any) {
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

    func scaleVideo(asset:AVAsset){
        VideoUtility.shared.scaleAsset(by: scaleFactor, withMode: speedMode, objVideoAsset, startTime: CMTime.zero, duration: asset.duration, completion: { (result) in
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
                    self.convertBtn.isSelected = true
                    self.convertBtn.setTitle("Save to Photos", for: .selected)
                    self.loadAsset(AVAsset(url: videoURL))
                    self.showPlayButton(true)
                    self.videoSpeedControlsView.isHidden = true
                }
                break
            }
        })
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
            UISaveVideoAtPathToSavedPhotosAlbum(self.objDestinationURL.path, self, #selector(SlowFastVideoViewController.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
            HUD.hide()
        }else{
            self.scaleVideo(asset:objVideoAsset)
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
    
    @IBAction func onPressSegment(_ sender: UISegmentedControl) {
        speedMode = SpeedoMode(rawValue: sender.selectedSegmentIndex)!
    }
    
    @IBAction func onPressStepper(_ sender: UIStepper) {
        scaleSpeedLabel.text = "Speed : " + Int(sender.value).description + "x"
        scaleFactor = ScaleFactor(rawValue: Int64(sender.value))!
    }
}
