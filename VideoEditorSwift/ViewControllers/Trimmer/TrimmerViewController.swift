//
//  TrimmerViewController.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import UIKit
import AVFoundation
import AVKit
import Gallery
//import MobileCoreServices
import SDWebImage
//import MobileCoreServices
import PryntTrimmerView
//import Regift
import ImageIO
import PKHUD

class TrimmerViewController: UIViewController{
    
    //MARK:- Outlets
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var trimmerView: TrimmerView!
    @IBOutlet weak var convertBtn: UIButton!    
    @IBOutlet var loadPreviewImageView: FLAnimatedImageView!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var gifBtn: UIButton!
    
    //MARK:- Vars and Objects
    
    var player: AVPlayer?
    var playbackTimeCheckerTimer: Timer?
    var trimmerPositionChangedTimer: Timer?
    var objVideoAsset:AVAsset!
    var videoURL:URL!
    var objtotalDuration:Double!
    var objstartTime:Double!
    var objGIFDuration:Double!
    var objDestinationURL:URL!
    var objSourceURL:URL!
    var objImages:[UIImage]!
    var objLoopCount:Int = 0
    var objFrameDelay:Double!
    var imgGIF:UIImage!
    var objImgData:Data!
    var currentFeature:AppFeatures!
    var audioPlayer: AVAudioPlayer?
    var isVideoConvertedToAudio: Bool = false
    var screenTitle: String?
    
    //MARK:- Viewcontroller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        convertBtn.backgroundColor = BtnLayout.btnColor
        convertBtn.layer.cornerRadius = BtnLayout.btnRadius
        convertBtn.layer.borderWidth = BtnLayout.btnBorderWidth
        convertBtn.layer.borderColor = BtnLayout.btnBorderColor
        
        self.title = screenTitle
        gifBtn.layer.cornerRadius = gifBtn.frame.height/2
        switch currentFeature {
        case AppFeatures.videoToGIF?:
            convertBtn.setTitle("Convert To Gif", for: .normal)
        case AppFeatures.imagesToGIF?:
            self.objImages = VideoUtility.shared.getArrayOfImages(gifData: self.objImgData)
            loadPreviewImageView.image = objImages.first
            gifBtn.isHidden = false
            loadPreviewImageView.isHidden = false
            playerView.isHidden = true
            trimmerView.isHidden = true
            convertBtn.setTitle("Share Gif", for: .normal)
            playBtn.isHidden = true
            pauseBtn.isHidden = true
        case AppFeatures.videoToAudio?:
            convertBtn.setTitle("Convert To Audio", for: .normal)
        case AppFeatures.videoCutter?:
            convertBtn.setTitle("Trim Video", for: .normal)
        case AppFeatures.captureImage?:
            convertBtn.setTitle("Capture Image", for: .normal)
        default:
            print("Default")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
            if self.currentFeature == AppFeatures.imagesToGIF{
                print("Images to gif")
            }else{
                self.loadAsset(self.objVideoAsset)
            }
        }
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    @IBAction func closeAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        loadInterstitialAd()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let player = self.player{
            player.pause()
        }
        
        if let audioPlayer = self.audioPlayer{
            audioPlayer.stop()
        }
    }
    
    //MARK:- Button Action Methods
    
    @IBAction func onPressConvertVideo(_ sender: UIButton) {
        if self.currentFeature == AppFeatures.imagesToGIF{
            let activityController = UIActivityViewController(activityItems: [self.objImgData!], applicationActivities: nil)
            activityController.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                if !completed {
                    // User canceled
                    return
                }
                // User completed activity
            }
            
            self.present(activityController, animated: true, completion: nil)
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
            if let asset = self.trimmerView.asset {
                HUD.show(.systemActivity)
                print(self.currentFeature!)
                switch self.currentFeature {
                case AppFeatures.videoToGIF?:
                    if self.convertBtn.isSelected {
                        let activityController = UIActivityViewController(activityItems: [self.objImgData!], applicationActivities: nil)
                        self.present(activityController, animated: true, completion: {
                            HUD.hide()
                        })
                    }else{
                        self.videoToGif()
                    }
                case AppFeatures.videoToAudio?:
                    if self.convertBtn.isSelected {
                        let activityController = UIActivityViewController(activityItems: [self.objSourceURL!], applicationActivities: nil)
                        self.present(activityController, animated: true, completion: {
                            HUD.hide()
                        })
                    }else{
                        self.videoToAudio()
                    }
                case AppFeatures.videoCutter?:
                    if self.convertBtn.isSelected {
                        UISaveVideoAtPathToSavedPhotosAlbum(self.objDestinationURL.path, self, #selector(TrimmerViewController.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
                        HUD.hide()
                    }else{
                        self.trimVideo(asset)
                    }
                case AppFeatures.captureImage?:
                    if self.convertBtn.isSelected {
                        let imgData = try! Data(contentsOf: self.objDestinationURL)
                        if let image = UIImage(data: imgData){
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        }
                        self.convertBtn.isSelected = false
                        self.convertBtn.setTitle("Capture Image", for: .selected)
                        HUD.hide()
                    }else{
                        self.captureImage(asset: asset)
                    }
                default:
                    print("Default")
                }
            }
        }
    }
    
    @IBAction func onPressPlayVideo(_ sender: UIButton?) {
        
        if currentFeature == AppFeatures.captureImage{
            self.convertBtn.isSelected = false
            self.convertBtn.setTitle("Capture Image", for: .selected)
        }

        if isVideoConvertedToAudio{
            self.playUsingAVAudioPlayer(url: self.objDestinationURL)
            self.showPlayButton(false)
        }else{
            guard let player = player else { return }
            player.play()
            self.showPlayButton(false)
            startPlaybackTimeChecker()
        }
    }
    
    @IBAction func onPressPauseVideo(_ sender: UIButton?) {
        if isVideoConvertedToAudio{
            if let audioPlayer = self.audioPlayer{
                audioPlayer.pause()
                self.showPlayButton(true)
            }
        }else{
            guard let player = player else { return }
            player.pause()
            self.showPlayButton(true)
            startPlaybackTimeChecker()
        }
    }

    @IBAction func onPressGIF(_ sender: UIButton?) {
        if gifBtn.isSelected{
            gifBtn.isSelected = false
            loadPreviewImageView.stopAnimating()
        }else{
            gifBtn.isSelected = false
            loadPreviewImageView.animationImages = objImages
            // Set the duration of the UIImage
            if currentFeature == AppFeatures.videoToGIF{
                loadPreviewImageView.animationDuration = CMTimeGetSeconds((self.trimmerView.endTime! - self.trimmerView.startTime!))
            }
            // Set the repetitioncount
            loadPreviewImageView.animationRepeatCount = 2
            // Start the animation
            loadPreviewImageView.startAnimating()
            gifBtn.isHidden = true
            self.perform(#selector(didFinishAnimatingImageView), with: nil, afterDelay: loadPreviewImageView.animationDuration*2)
        }
    }
    
    //MARK:- Other Methods
    
    func playUsingAVAudioPlayer(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print(error)
        }
    }

    @available(iOS 11.0, *)
    func showScreenshotEffect() {
        
        let snapshotView = UIView()
        snapshotView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(snapshotView)
        
        let constraints:[NSLayoutConstraint] = [
            snapshotView.topAnchor.constraint(equalTo: view.topAnchor),
            snapshotView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            snapshotView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            snapshotView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
        snapshotView.backgroundColor = UIColor.white
        UIView.animate(withDuration: 0.2, animations: {
            snapshotView.alpha = 0
        }) { _ in
            snapshotView.removeFromSuperview()
        }
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

    /*
     private func getTransform(for videoTrack: AVAssetTrack) -> CGAffineTransform {
     
     let renderSize = CGSize(width: 16 * 2 * 18,
     height: 16 * 3 * 18)
     let cropFrame = videoCropView.getImageCropFrame()
     let renderScale = renderSize.width / cropFrame.width
     let offset = CGPoint(x: -cropFrame.origin.x, y: -cropFrame.origin.y)
     let rotation = atan2(videoTrack.preferredTransform.b, videoTrack.preferredTransform.a)
     
     var rotationOffset = CGPoint(x: 0, y: 0)
     
     if videoTrack.preferredTransform.b == -1.0 {
     rotationOffset.y = videoTrack.naturalSize.width
     } else if videoTrack.preferredTransform.c == -1.0 {
     rotationOffset.x = videoTrack.naturalSize.height
     } else if videoTrack.preferredTransform.a == -1.0 {
     rotationOffset.x = videoTrack.naturalSize.width
     rotationOffset.y = videoTrack.naturalSize.height
     }
     
     var transform = CGAffineTransform.identity
     transform = transform.scaledBy(x: renderScale, y: renderScale)
     transform = transform.translatedBy(x: offset.x + rotationOffset.x, y: offset.y + rotationOffset.y)
     transform = transform.rotated(by: rotation)
     
     print("track size \(videoTrack.naturalSize)")
     print("preferred Transform = \(videoTrack.preferredTransform)")
     print("rotation angle \(rotation)")
     print("rotation offset \(rotationOffset)")
     print("actual Transform = \(transform)")
     return transform
     }
     */
    func loadAsset(_ asset: AVAsset) {
        
        trimmerView.maxDuration = CMTimeGetSeconds(asset.duration)
        trimmerView.asset = asset
        trimmerView.delegate = self as TrimmerViewDelegate
        addVideoPlayer(with: asset, playerView: playerView)
    }
    
    private func addVideoPlayer(with asset: AVAsset, playerView: UIView) {
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
        if let startTime = trimmerView.startTime {
            player?.seek(to: startTime)
            self.showPlayButton(true)
        }
    }
    
    func startPlaybackTimeChecker() {
        
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                                                        selector:
            #selector(TrimmerViewController.onPlaybackTimeChecker), userInfo: nil, repeats: true)
    }
    
    func stopPlaybackTimeChecker() {
        
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    @objc func onPlaybackTimeChecker() {
        
        guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime, let player = player else {
            return
        }
        
        let playBackTime = player.currentTime()
        trimmerView.seek(to: playBackTime)
        
        if playBackTime >= endTime {
            player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
        }
    }
    
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        return context.createCGImage(inputImage, from: inputImage.extent)
    }
    
    func clearTempFolder() {
        let fileManager = FileManager.default
        let tempFolderPath = NSTemporaryDirectory()
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: tempFolderPath)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: tempFolderPath + filePath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    
    func checkForDirectory(directoryName : String) {
        let filemanager = FileManager()
        let url = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first
        var finalPath = url?.appendingPathComponent(directoryName)
        if filemanager.fileExists(atPath: (finalPath?.path)!) {
            //                                finalPath = finalPath?.appendingPathComponent("Documents")
        }else {
            
            let documentsPath1 = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
            let logsPath = documentsPath1.appendingPathComponent(directoryName)
            print(logsPath!)
            do {
                try FileManager.default.createDirectory(atPath: logsPath!.path, withIntermediateDirectories: true, attributes: nil)
                
                finalPath = logsPath
                
            } catch let error as NSError {
                NSLog("Unable to create directory \(error.debugDescription)")
            }
        }
        print(finalPath?.path as Any)
    }
    
    @objc func didFinishAnimatingImageView(){
        gifBtn.isHidden = false
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

    //MARK:- Conversion Methods
    
    func trimVideo(_ asset:AVAsset) {
        
        if let player = self.player{
            player.pause()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            VideoUtility.shared.trimVideo(asset, startTime: self.trimmerView.startTime!, duration: (self.trimmerView.endTime! - self.trimmerView.startTime!), completion: { (result) in
                switch result{
                case .Error(let strError):
                    showAlert(message: strError, buttonClicked: nil)
                    break
                case .Success(let videoURL):
                    self.objDestinationURL = videoURL
                    self.trimmerView.isHidden = true
                    self.convertBtn.isSelected = true
                    self.convertBtn.setTitle("Save to Photos", for: .selected)
                    self.loadAsset(AVAsset(url: videoURL))
                    self.showPlayButton(true)
                    break
                }
                HUD.hide()
            })
        })

        /*
        guard let asset = trimmerView.asset, let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            return
        }
        
        let assetComposition = AVMutableComposition()
        let frame1Time = trimmerView.endTime
        let trackTimeRange = CMTimeRangeMake(start: trimmerView.startTime!, duration: frame1Time!)
        
        guard let videoCompositionTrack = assetComposition.addMutableTrack(withMediaType: .video,
                                                                           preferredTrackID: kCMPersistentTrackID_Invalid) else {
                                                                            return
        }
        
        try videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: CMTime.zero)
        
        if let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first {
            let audioCompositionTrack = assetComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                         preferredTrackID: kCMPersistentTrackID_Invalid)
            try audioCompositionTrack?.insertTimeRange(trackTimeRange, of: audioTrack, at: CMTime.zero)
        }
        
        //1. Create the instructions
        let mainInstructions = AVMutableVideoCompositionInstruction()
        mainInstructions.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
        
        //2 add the layer instructions
        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
        
        let renderSize = videoTrack.naturalSize
        //        let transform = getTransform(for: videoTrack)
        
        //        layerInstructions.setTransform(transform, at: kCMTimeZero)
        layerInstructions.setOpacity(1.0, at: CMTime.zero)
        mainInstructions.layerInstructions = [layerInstructions]
        
        //3 Create the main composition and add the instructions
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.instructions = [mainInstructions]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        let tempUrl = URL(fileURLWithPath: "\(NSTemporaryDirectory())TrimmedMovie.mov")
        try? FileManager.default.removeItem(at: tempUrl)
        
        let exportSession = AVAssetExportSession(asset: assetComposition, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = AVFileType.mov
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.videoComposition = videoComposition
        exportSession?.outputURL = tempUrl
        exportSession?.exportAsynchronously(completionHandler: {
            
            DispatchQueue.main.async {
                
                if let url = exportSession?.outputURL, exportSession?.status == .completed {
                    let filemanager = FileManager()
                    let docDirUrl = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first
                    self.checkForDirectory(directoryName: Directories.Video.rawValue)
                    
                    let timestamp = String(Date().ticks)
                    let VideoPath = url
                    let finalPath = docDirUrl?.appendingPathComponent(Directories.Video.rawValue + "/MY_" + timestamp + "." + VideoPath.pathExtension)
                    print(VideoPath)
                    
                    do {
                        if filemanager.fileExists(atPath: (finalPath?.path)!) {
                            //do nothing
                        }else {
                            try filemanager.copyItem(at:VideoPath, to: finalPath!)
                            self.objSourceURL = finalPath
                            UISaveVideoAtPathToSavedPhotosAlbum(finalPath!.path, nil, nil, nil)
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                    print(finalPath as Any)
                    
                    HUD.flash(.success)
                } else {
                    let error = exportSession?.error
                    print("error exporting video \(String(describing: error))")
                    HUD.flash(.error)
                }
                self.clearTempFolder()
            }
        })
         */
    }
    
    func videoToAudio(){
        if let player = self.player {
            player.pause()
        }

        guard let asset = trimmerView.asset else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            VideoUtility.shared.convertVideoToAudio(asset, startTime: self.trimmerView.startTime!, duration: self.trimmerView.endTime! - self.trimmerView.startTime!) { (result) in
                switch result{
                case .Error(let strError):
                    showAlert(message: strError, buttonClicked: nil)
                    break
                case .Success(let audioURL):
                    DispatchQueue.main.async {
                        HUD.hide()
                        self.objSourceURL = audioURL
                        self.objDestinationURL = audioURL
                        self.isVideoConvertedToAudio = true
                        self.playerView.isHidden = true
                        self.trimmerView.isHidden = true
                        self.convertBtn.isSelected = true
                        self.convertBtn.setTitle("Share Audio", for: .selected)
                        self.showPlayButton(true)
                    }
                    break
                }
                HUD.hide()
            }
        })
        
        /*
        guard let asset = trimmerView.asset, let srcTrack = asset.tracks(withMediaType: AVMediaType.audio).first else {
            return
        }
        
        let newAudioAsset = AVMutableComposition()
        let frame1Time = trimmerView.endTime
        let trackTimeRange = CMTimeRangeMake(start: trimmerView.startTime!, duration: frame1Time!)
        
        guard let dstCompositionTrack = newAudioAsset.addMutableTrack(withMediaType: .audio,
                                                                      preferredTrackID: kCMPersistentTrackID_Invalid) else {
                                                                        return
        }
        
        let tempUrl = URL(fileURLWithPath: "\(NSTemporaryDirectory())TrimmedAudio.m4a")
        try? FileManager.default.removeItem(at: tempUrl)
        
        do {
            try dstCompositionTrack.insertTimeRange(trackTimeRange, of: srcTrack, at: CMTime.zero)
            let exportSession = AVAssetExportSession(asset: newAudioAsset, presetName: AVAssetExportPresetPassthrough)
            exportSession?.outputFileType = AVFileType.m4a
            exportSession?.outputURL = tempUrl
            exportSession?.exportAsynchronously(completionHandler: {
                DispatchQueue.main.async {
                    if let url = exportSession?.outputURL,exportSession?.status == .completed {
                        let filemanager = FileManager()
                        let docDirUrl = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first
                        self.checkForDirectory(directoryName: Directories.Audio.rawValue)
                        
                        let timestamp = String(Date().ticks)
                        let AudioPath = url
                        let finalPath = docDirUrl?.appendingPathComponent(Directories.Audio.rawValue + "/MY_" + timestamp + ".m4a")
                        print(AudioPath)
                        
                        do {
                            if filemanager.fileExists(atPath: (finalPath?.path)!) {
                                //do nothing
                            }else {
                                try filemanager.copyItem(at:AudioPath, to: finalPath!)
                                self.objDestinationURL = finalPath
                                self.objSourceURL = finalPath
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }else{
                        print(exportSession?.error?.localizedDescription)
                    }
                    self.clearTempFolder()
                    HUD.hide()
                    self.isVideoConvertedToAudio = true
                    self.playerView.isHidden = true
                    self.trimmerView.isHidden = true
                    self.convertBtn.isSelected = true
                    self.convertBtn.setTitle("Share Audio", for: .selected)
                    self.showPlayButton(true)
                }
            })
        } catch {
            DispatchQueue.main.async {
         HUD.hide()
         }
         print(error.localizedDescription)
         }
         */
    }
    
    func videoToGif(){
        if let player = self.player {
            player.pause()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            VideoUtility.shared.convertAndCompressVideo(asset: AVAsset(url: self.videoURL)) { (result) in
                switch result{
                case .Error(let strError):
                    HUD.hide()
                    showAlert(message: strError, buttonClicked: nil)
                    break
                case .Success(let finalURL):
                    DispatchQueue.main.async {
                        VideoUtility.shared.convertVideoToGif(finalURL, startTime: Float(CMTimeGetSeconds(self.trimmerView.startTime!)), duration: Float(CMTimeGetSeconds((self.trimmerView.endTime! - self.trimmerView.startTime!)))) { (result) in
                            HUD.hide()
                            switch result{
                            case .Error(let strError):
                                showAlert(message: strError, buttonClicked: nil)
                                break
                            case .Success(let imgURL):
                                do{
                                    self.objImgData = try Data(contentsOf: imgURL)
                                    self.objImages = VideoUtility.shared.getArrayOfImages(gifData: self.objImgData)
                                    self.loadPreviewImageView.image = self.objImages.first
                                    self.playerView.isHidden = true
                                    self.loadPreviewImageView.isHidden = false
                                    self.gifBtn.isHidden = false
                                    self.trimmerView.isHidden = true
                                    self.convertBtn.isSelected = true
                                    self.convertBtn.setTitle("Share GIF", for: .selected)
                                    self.playBtn.isHidden = true
                                    self.pauseBtn.isHidden = true
                                    self.showPlayButton(true)
                                }catch{
                                    print("Could not generate Data from the Image URL. Error: \(error.localizedDescription)")
                                }
                                break
                            }
                        }
                    }
                    break
                }
            }
        })
        
//        let trimmedRegift = Regift(sourceFileURL: videoURL, startTime: startTime, duration: duration, frameRate: frameRate, loopCount: loopCount)
//        if trimmedRegift.createGif() != nil{
//            do {
//                let imgData = try Data(contentsOf: trimmedRegift.createGif()!)
//                let imageURL = UIImage.sd_animatedGIF(with: imgData)
//                playerView.isHidden = true
//                loadPreviewImageView.isHidden = false
//                trimmerView.isHidden = true
//                loadPreviewImageView.image = imageURL
//                convertBtn.isSelected = true
//                convertBtn.setTitle("Share GIF", for: .selected)
//                self.objImgData = imgData
//                playBtn.isHidden = true
//                pauseBtn.isHidden = true
//
//                let filemanager = FileManager()
//                let url = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first
//                self.checkForDirectory(directoryName: Directories.GIF.rawValue)
//
//                let timestamp = String(Date().ticks)
//                let finalPath = url?.appendingPathComponent(Directories.GIF.rawValue + "/TE_" + timestamp + ".gif")
//                do {
//                    if filemanager.fileExists(atPath: (finalPath?.path)!) {
//                        //do nothing
//                    }else {
//                        try filemanager.copyItem(at: trimmedRegift.createGif()!, to: finalPath!)
//                        clearTempFolder()
//                    }
//                } catch {
//                    print(error.localizedDescription)
//                }
//
//                DispatchQueue.main.async {
//                    HUD.hide()
//                }
//            } catch {
//                print("Unable to convert data: \(error)")
//            }
//        }else{
//            let alert = UIAlertController(title: "Error", message: "Cannot convert huge file size to GIF.", preferredStyle: .alert)
//            let actionOk = UIAlertAction(title: "Ok", style: .default, handler: nil)
//            alert.addAction(actionOk)
//            self.navigationController?.present(alert, animated: true, completion: nil)
//        }
    }
    
    func captureImage(asset: AVAsset){
        
        guard let asset = self.trimmerView.asset else {
            return
        }
        
        if let player = self.player{
            player.pause()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            VideoUtility.shared.captureImageFromVideo(asset: asset, selectedTime: self.player?.currentTime() ?? CMTime.zero, completion: { (result) in
                switch result{
                case .Error(let strError):
                    showAlert(message: strError, buttonClicked: nil)
                    break
                case .Success(let imageURL):
                    showAlert(message: "Image successfully saved.", buttonClicked: nil)
                    self.objDestinationURL = imageURL
                    self.convertBtn.isSelected = true
                    self.convertBtn.setTitle("Save to Photos", for: .selected)
                    self.showPlayButton(true)
                    break
                }
                HUD.hide()
            })
        })
        
        /*
        if let selectedTime = self.player?.currentTime() {
            let generator = AVAssetImageGenerator(asset: asset)
            generator.requestedTimeToleranceBefore = CMTime.zero
            generator.requestedTimeToleranceAfter = CMTime.zero
            generator.appliesPreferredTrackTransform = true
            var actualTime = CMTime.zero
            let image = try? generator.copyCGImage(at: selectedTime, actualTime: &actualTime)
            if let image = image {
                
                let selectedImage = UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .up)
                UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil)
                let filemanager = FileManager()
                let url = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first
                self.checkForDirectory(directoryName: Directories.Image.rawValue)
                
                let timestamp = String(Date().ticks)
                let finalPath = url?.appendingPathComponent(Directories.Image.rawValue + "/MY_" + timestamp + ".jpg")
                
                if let data = selectedImage.jpegData(compressionQuality: 1.0),!FileManager.default.fileExists(atPath: (finalPath?.path)!){
                    do {
                        // writes the image data to disk
                        try data.write(to: finalPath!)
                        print("file saved")
                        HUD.flash(.success)
                    } catch {
                        print("error saving file:", error)
                        HUD.flash(.error)
                    }
                    guard let player = self.player else { return }
                    player.pause()
                    self.showPlayButton(true)
                }
                print(finalPath as Any)
            }
        }
         */
    }
}

//MARK:- Extensions

extension TrimmerViewController: TrimmerViewDelegate {
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        player?.play()
        self.showPlayButton(false)
        startPlaybackTimeChecker()
    }
    
    func didChangePositionBar(_ playerTime: CMTime) {
        stopPlaybackTimeChecker()
        player?.pause()
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
        print(duration)
    }
}
extension TrimmerViewController:UIGestureRecognizerDelegate{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        return true
    }
    
}

extension TrimmerViewController: AVAudioPlayerDelegate{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.showPlayButton(true)
    }
}
