//
//  HomeViewController.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import UIKit
import Regift
import Gallery
import AVKit
import SDWebImage
import MobileCoreServices
import Photos
import PKHUD
import AssetsPickerViewController

struct Functionalities {
    var name:String
    var imgIcon:UIImage
}

public class HomeViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var videoPreviewView: UIView!
    @IBOutlet weak var videoPreviewBaseView: UIView!
    @IBOutlet weak var switchCameraBtn: UIButton!
    
    //Mark:-Global Declareation
    
    var currentFeature:AppFeatures!
    var arrFunctionalities:[Functionalities] = []
    var currentIndex: Int!
    
    // Record Video
    let captureSession = AVCaptureSession()
    let movieFileOutput = AVCaptureMovieFileOutput()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var deviceInput: AVCaptureDeviceInput!
    var outputURL: URL!
    var leftBarButtonItem:UIBarButtonItem!
    
    public var dateFormatter = DateFormatter()
    
    @IBOutlet weak var headerLabel: UILabel!
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        let bundle = Bundle(for: type(of:self))
        arrFunctionalities.append(Functionalities(name: "Video to GIF", imgIcon: UIImage(named: "video_gif", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "Images to GIF", imgIcon: UIImage(named: "image_gif", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "Video to Mp3", imgIcon: UIImage(named: "video_audio", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "Video Cutter", imgIcon: UIImage(named: "video_cutter", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "Video to Image", imgIcon: UIImage(named: "capture_image", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "Slow/Fast Video", imgIcon: UIImage(named: "slowFastVideo", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "Add Watermark", imgIcon: UIImage(named: "watermark_vidoe", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "Video Filter", imgIcon: UIImage(named: "video_filter", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "Reverse Video", imgIcon: UIImage(named: "reverse_video", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "Merge Video", imgIcon: UIImage(named: "merge_video", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "My Studio", imgIcon: UIImage(named: "gallery", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "More Apps", imgIcon: UIImage(named: "gallery", in: bundle, compatibleWith: nil)!))
        
        self.videoPreviewBaseView.isHidden = true
        self.videoPreviewBaseView.alpha = 0.0
        leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onPressCancelVideoCapture))
        
        headerLabel.font = UIFont(name: "Staatliches-Regular", size: 24)
                
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
            if self.setupSession() {
                self.setupPreview()
            }
        }
        
    }
    
    @IBAction func privacyPolicyBtn(_ sender: Any) {
        UIApplication.shared.open(AppConfig.privacyURL)
    }
    
    @objc func onPressCancelVideoCapture(){
        UIView.animate(withDuration: 0.2, animations: {
            self.videoPreviewBaseView.alpha = 0.0
            self.videoPreviewBaseView.layoutIfNeeded()
        }, completion: { (complete) in
            self.navigationItem.leftBarButtonItem = nil
            self.videoPreviewBaseView.isHidden = true
            self.stopSession()
        })
    }
    
    func setupPreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.frame = videoPreviewView.bounds
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewView.layer.addSublayer(videoPreviewLayer)
    }
   
    
    //MARK:- Setup Camera
    func setupSession() -> Bool {
        
        if Platform.isSimulator {
            return false
        }
        
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        
        let camera = AVCaptureDevice.default(for: AVMediaType.video)!
        if camera.isFocusModeSupported(.continuousAutoFocus){
            try! camera.lockForConfiguration()
            camera.focusMode = .continuousAutoFocus
            camera.unlockForConfiguration()
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                deviceInput = input
            }
        } catch {
            print("Error setting device video input: \(error)")
            return false
        }
        
        let microphone = AVCaptureDevice.default(for: AVMediaType.audio)!
        
        do {
            let micInput = try AVCaptureDeviceInput(device: microphone)
            if captureSession.canAddInput(micInput) {
                captureSession.addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return false
        }
        
        if captureSession.canAddOutput(movieFileOutput) {
            captureSession.addOutput(movieFileOutput)
        }
        
        return true
    }
    
    func getDevice(_ position:AVCaptureDevice.Position) -> AVCaptureDevice? {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            let camera =  AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            return camera
        }
        
        return camera
    }
    
    func startSession() {
        
        if !captureSession.isRunning {
            DispatchQueue.main.async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            DispatchQueue.main.async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        
        return orientation
    }
    
    @IBAction func onPressSwitchCamera(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        guard let currentInputDevice = captureSession.inputs.filter({$0 == deviceInput}).first else{
            _ = self.setupSession()
            return
        }
        
        self.captureSession.beginConfiguration()
        
        var camera:AVCaptureDevice!
        if sender.isSelected{
            camera = self.getDevice(.front)
        }else{
            camera = self.getDevice(.back)
        }
        
        if camera.isFocusModeSupported(.continuousAutoFocus){
            try! camera.lockForConfiguration()
            camera.focusMode = .continuousAutoFocus
            camera.unlockForConfiguration()
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.removeInput(currentInputDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                deviceInput = input
            }
        } catch {
            print("Error setting device video input: \(error)")
            return
        }
        
        self.captureSession.commitConfiguration()
    }
    
    @IBAction func startCapture(_ sender:UIButton) {
        
        if movieFileOutput.isRecording == false {
            let connection = movieFileOutput.connection(with: AVMediaType.video)
            
            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = currentVideoOrientation()
            }
            
            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
                connection?.videoOrientation = .portrait
            }
            
            let device = deviceInput.device
            
            if (device.isSmoothAutoFocusSupported) {
                
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print("Error setting configuration: \(error)")
                }
                
            }
            outputURL = tempURL()
            movieFileOutput.startRecording(to: outputURL, recordingDelegate: self)
            sender.isSelected = true
            switchCameraBtn.isHidden = true
        }
        else {
            sender.isSelected = false
            stopRecording()
            switchCameraBtn.isHidden = false
        }
    }
    
    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mov")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    func stopRecording() {
        
        if movieFileOutput.isRecording == true {
            movieFileOutput.stopRecording()
        }
    }
    
    func showGalleryView(){
        let gallery = GalleryController()
        gallery.delegate = self
        present(gallery, animated: true, completion: nil)
    }
    
    func showCaptureCameraView(){
        DispatchQueue.main.async {
            self.startSession()
            self.videoPreviewBaseView.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.videoPreviewBaseView.alpha = 1.0
                self.videoPreviewBaseView.layoutIfNeeded()
            }, completion: { (complete) in
                self.navigationItem.leftBarButtonItem = self.leftBarButtonItem
            })
        }
    }
    
    func showVideoActionSheet(selectVideo:((UIAlertAction) -> Void)?, captureVideo:((UIAlertAction) -> Void)?){
        let actionSheet = UIAlertController(title: "", message: "Please Select", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Select Video", style: .default, handler: selectVideo))
        actionSheet.addAction(UIAlertAction(title: "Capture Video", style: .default, handler: captureVideo))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
}

extension HomeViewController:UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrFunctionalities.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let objVideoFunctionalityCollectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeCell", for: indexPath)as! HomeCell
        objVideoFunctionalityCollectionCell.lblForVideoEditName.text = arrFunctionalities[indexPath.row].name
        objVideoFunctionalityCollectionCell.imgForUtilityIcon.image = arrFunctionalities[indexPath.row].imgIcon
        objVideoFunctionalityCollectionCell.imgForUtilityIcon.image =  objVideoFunctionalityCollectionCell.imgForUtilityIcon.image?.withRenderingMode(.alwaysTemplate)
        objVideoFunctionalityCollectionCell.imgForUtilityIcon.tintColor = #colorLiteral(red: 0.2666666667, green: 0.1568627451, blue: 0.4666666667, alpha: 1)
        
        objVideoFunctionalityCollectionCell.lblForVideoEditName.font = UIFont(name: "SairaSemiCondensed-Regular", size: 16)
        
        if(UIDevice.current.userInterfaceIdiom == .pad){
            objVideoFunctionalityCollectionCell.lblForVideoEditName.font = UIFont(name: "SairaSemiCondensed-Regular", size: 30)
        }
        
        
        if(arrFunctionalities[indexPath.row].name == ""){
            objVideoFunctionalityCollectionCell.imgForUtilityIcon.tintColor = #colorLiteral(red: 0.2666666667, green: 0.1568627451, blue: 0.4666666667, alpha: 0)
        }
        return objVideoFunctionalityCollectionCell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        currentIndex = indexPath.row
        
        
        if indexPath.row == 0{
            showVideoActionSheet(selectVideo: { (action) in
                // Select Video
                Config.tabsToShow = [.videoTab]
                self.currentFeature = AppFeatures.videoToGIF
                self.showGalleryView()
            }) { (action) in
                // Capture Video
                self.currentFeature = AppFeatures.videoToGIF
                self.showCaptureCameraView()
            }
        }else if indexPath.row == 1{
            
            Config.tabsToShow = [.imageTab]
            self.currentFeature = AppFeatures.imagesToGIF
            self.showGalleryView()
            
        } else if indexPath.row == 2{
            showVideoActionSheet(selectVideo: { (action) in
                // Select Video
                Config.tabsToShow = [.videoTab]
                self.currentFeature = AppFeatures.videoToAudio
                self.showGalleryView()
            }) { (action) in
                // Capture Video
                self.currentFeature = AppFeatures.videoToAudio
                self.showCaptureCameraView()
            }
        } else if indexPath.row == 3{
            showVideoActionSheet(selectVideo: { (action) in
                // Select Video
                Config.tabsToShow = [.videoTab]
                self.currentFeature = AppFeatures.videoCutter
                self.showGalleryView()
            }) { (action) in
                // Capture Video
                self.currentFeature = AppFeatures.videoCutter
                self.showCaptureCameraView()
            }
        } else if indexPath.row == 4{
            
            showVideoActionSheet(selectVideo: { (action) in
                // Select Video
                Config.tabsToShow = [.videoTab]
                self.currentFeature = AppFeatures.captureImage
                self.showGalleryView()
            }) { (action) in
                // Capture Video
                self.currentFeature = AppFeatures.captureImage
                self.showCaptureCameraView()
            }
        }else if indexPath.row == 5{
            showVideoActionSheet(selectVideo: { (action) in
                // Select Video
                Config.tabsToShow = [.videoTab]
                self.currentFeature = AppFeatures.slowFastVideo
                self.showGalleryView()
            }) { (action) in
                // Capture Video
                self.currentFeature = AppFeatures.slowFastVideo
                self.showCaptureCameraView()
            }
        }else if indexPath.row == 6{
            showVideoActionSheet(selectVideo: { (action) in
                // Select Video
                Config.tabsToShow = [.videoTab]
                self.currentFeature = AppFeatures.watermarkVideo
                self.showGalleryView()
            }) { (action) in
                // Capture Video
                self.currentFeature = AppFeatures.watermarkVideo
                self.showCaptureCameraView()
            }
        }else if indexPath.row == 7{
            showVideoActionSheet(selectVideo: { (action) in
                // Select Video
                Config.tabsToShow = [.videoTab]
                self.currentFeature = AppFeatures.videoFilter
                self.showGalleryView()
            }) { (action) in
                // Capture Video
                self.currentFeature = AppFeatures.videoFilter
                self.showCaptureCameraView()
            }
        }else if indexPath.row == 8{
            showVideoActionSheet(selectVideo: { (action) in
                // Select Video
                Config.tabsToShow = [.videoTab]
                self.currentFeature = AppFeatures.reverseVideo
                self.showGalleryView()
            }) { (action) in
                // Capture Video
                self.currentFeature = AppFeatures.reverseVideo
                self.showCaptureCameraView()
            }
        }else if indexPath.row == 9{
            self.currentFeature = AppFeatures.mergeVideo
            let pickerConfig = AssetsPickerConfig()
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            options.sortDescriptors = [NSSortDescriptor(key: "duration", ascending: true)]
            pickerConfig.assetFetchOptions = [
                .smartAlbum: options,
                .album: options
            ]
            let picker = AssetsPickerViewController()
            picker.navigationController?.navigationBar.backgroundColor = UIColor.white
            picker.pickerConfig = pickerConfig
            picker.pickerDelegate = self
            self.navigationController?.present(picker, animated: true, completion: {
                
                self.setStatusBarStyle()
                //                guard let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as? UIView else {return}
                //                statusBar.backgroundColor = UIColor.white
            })
        }
        else if indexPath.row == 10
        {
            let objSaveItemGalleryViewController = StoryBoards.objSaveItemGallerySB.instantiateViewController(withIdentifier: "SaveItemGalleryViewController")as! SaveItemGalleryViewController
            objSaveItemGalleryViewController.dateFormatter = self.dateFormatter
            self.navigationController?.pushViewController(objSaveItemGalleryViewController, animated: true)
        }
        else if indexPath.row == 11
        {
            UIApplication.shared.open(NSURL(string : AppConfig.moreapp)! as URL, options: [:], completionHandler: nil)
        }
    }
    func setStatusBarStyle() {
        if #available(iOS 13.0, *) {
            let app = UIApplication.shared
            let statusBarHeight: CGFloat = app.statusBarFrame.size.height
            
            let statusbarView = UIView()
            statusbarView.backgroundColor = UIColor.white//UIColor(red: 29.0/255.0, green: 99.0/255.0, blue: 170.0/255.0, alpha: 1)
            view.addSubview(statusbarView)
            
            statusbarView.translatesAutoresizingMaskIntoConstraints = false
            statusbarView.heightAnchor
                .constraint(equalToConstant: statusBarHeight).isActive = true
            statusbarView.widthAnchor
                .constraint(equalTo: view.widthAnchor, multiplier: 1.0).isActive = true
            statusbarView.topAnchor
                .constraint(equalTo: view.topAnchor).isActive = true
            statusbarView.centerXAnchor
                .constraint(equalTo: view.centerXAnchor).isActive = true
        } else {
            let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView
            statusBar?.backgroundColor = UIColor.white//UIColor(red: 29.0/255.0, green: 99.0/255.0, blue: 170.0/255.0, alpha: 1)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let yourWidth = collectionView.bounds.width/3
        let yourHeight = yourWidth
        
        return CGSize(width: yourWidth, height: yourHeight)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension HomeViewController: GalleryControllerDelegate{
    public func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        
        controller.dismiss(animated: true, completion: nil)
        
        if currentFeature == .imagesToGIF{
            var counter:Int = 0
            var arrImages:[UIImage] = []
            for imageAsset in images{
                imageAsset.resolve { (image) in
                    counter += 1
                    arrImages.append(image!)
                    if counter == images.count{
                        HUD.show(.systemActivity)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                            VideoUtility.shared.convertImagesToGIF(with: arrImages, frameDelay: 0.7, completion: { (result) in
                                HUD.hide()
                                
                                switch result{
                                case .Error(let strError):
                                    showAlert(message: strError, buttonClicked: nil)
                                    break
                                case .Success(let imgData):
                                    let imageGIF = UIImage.sd_animatedGIF(with: imgData)
                                    
                                    let objTrimmerVC = StoryBoards.objTrimmerViewController.instantiateViewController(withIdentifier: "TrimmerViewController")as! TrimmerViewController
                                    objTrimmerVC.objImgData = imgData
                                    objTrimmerVC.imgGIF = imageGIF
                                    objTrimmerVC.currentFeature = self.currentFeature
                                    objTrimmerVC.screenTitle = self.arrFunctionalities[self.currentIndex].name
                                    self.navigationController?.pushViewController(objTrimmerVC, animated: true)
                                    break
                                }
                            })
                        })
                    }
                }
            }
        }
        
        
    }
    
    public func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        controller.dismiss(animated: true) {
            
            Config.VideoEditor.maximumDuration = 1800
            video.fetchAVAsset({ (avAsset) in
                
                if !(self.currentFeature == .videoCutter || self.currentFeature == .captureImage) && !(avAsset?.isCompatibleWithAirPlayVideo)!{
                    showAlert(message: "Unsupported video type. Please select another video", buttonClicked: nil)
                    return
                }
                if self.currentFeature == .videoToAudio{
                    let objTrimmerVC = StoryBoards.objTrimmerViewController.instantiateViewController(withIdentifier: "TrimmerViewController")as! TrimmerViewController
                    objTrimmerVC.objVideoAsset = avAsset
                    objTrimmerVC.currentFeature = self.currentFeature
                    objTrimmerVC.screenTitle = self.arrFunctionalities[self.currentIndex].name
                    self.navigationController?.pushViewController(objTrimmerVC, animated: true)
                }else if self.currentFeature == .videoToGIF {
                    let objTrimmerVC = StoryBoards.objTrimmerViewController.instantiateViewController(withIdentifier: "TrimmerViewController")as! TrimmerViewController
                    objTrimmerVC.videoURL = (avAsset as! AVURLAsset).url
                    objTrimmerVC.objtotalDuration = video.asset.duration
                    objTrimmerVC.objGIFDuration = video.asset.duration
                    objTrimmerVC.currentFeature = self.currentFeature
                    objTrimmerVC.objVideoAsset = avAsset
                    objTrimmerVC.screenTitle = self.arrFunctionalities[self.currentIndex].name
                    self.navigationController?.pushViewController(objTrimmerVC, animated: true)
                }else if self.currentFeature == .videoCutter{
                    let objTrimmerVC = StoryBoards.objTrimmerViewController.instantiateViewController(withIdentifier: "TrimmerViewController")as! TrimmerViewController
                    objTrimmerVC.objVideoAsset = avAsset
                    objTrimmerVC.currentFeature = self.currentFeature
                    objTrimmerVC.screenTitle = self.arrFunctionalities[self.currentIndex].name
                    self.navigationController?.pushViewController(objTrimmerVC, animated: true)
                }else if self.currentFeature == .captureImage{
                    let objTrimmerVC = StoryBoards.objTrimmerViewController.instantiateViewController(withIdentifier: "TrimmerViewController")as! TrimmerViewController
                    objTrimmerVC.objVideoAsset = avAsset
                    objTrimmerVC.currentFeature = self.currentFeature
                    objTrimmerVC.screenTitle = self.arrFunctionalities[self.currentIndex].name
                    self.navigationController?.pushViewController(objTrimmerVC, animated: true)
                }else if self.currentFeature == .slowFastVideo{
                    let objSlowFastVideoVC = StoryBoards.objSlowFastVideoViewController.instantiateViewController(withIdentifier: "SlowFastVideoViewController")as! SlowFastVideoViewController
                    objSlowFastVideoVC.objVideoAsset = avAsset
                    objSlowFastVideoVC.screenTitle = self.arrFunctionalities[self.currentIndex].name
                    self.navigationController?.pushViewController(objSlowFastVideoVC, animated: true)
                }else if self.currentFeature == .watermarkVideo{
                    let objWatermarkVideoVC = StoryBoards.objWatermarkVideoViewController.instantiateViewController(withIdentifier: "WatermarkVideoViewController")as! WatermarkVideoViewController
                    objWatermarkVideoVC.objVideoAsset = avAsset
                    objWatermarkVideoVC.screenTitle = self.arrFunctionalities[self.currentIndex].name
                    self.navigationController?.pushViewController(objWatermarkVideoVC, animated: true)
                }else if self.currentFeature == .videoFilter{
                    let objWatermarkVideoVC = StoryBoards.objVideoFilterViewController.instantiateViewController(withIdentifier: "VUVideoFilterVC")as! VUVideoFilterVC
                    objWatermarkVideoVC.objVideoAsset = avAsset
                    objWatermarkVideoVC.screenTitle = self.arrFunctionalities[self.currentIndex].name
                    self.navigationController?.pushViewController(objWatermarkVideoVC, animated: true)
                }else if self.currentFeature == .reverseVideo{
                    let objReverseVideoViewController = StoryBoards.objReverseVideoViewController.instantiateViewController(withIdentifier: "ReverseVideoViewController")as! ReverseVideoViewController
                    objReverseVideoViewController.objVideoAsset = avAsset
                    objReverseVideoViewController.screenTitle = self.arrFunctionalities[self.currentIndex].name
                    self.navigationController?.pushViewController(objReverseVideoViewController, animated: true)
                }                
            })
        }
    }
    
    public func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
    }
    
    public func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func checkDirectory() {
        let filemanager = FileManager()
        
        let url = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first
        var finalPath = url?.appendingPathComponent(Directories.GIF.rawValue)
        
        if filemanager.fileExists(atPath: (finalPath?.path)!) {
            //                                finalPath = finalPath?.appendingPathComponent("Documents")
        }else {
            
            let documentsPath1 = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
            let logsPath = documentsPath1.appendingPathComponent(Directories.GIF.rawValue)
            print(logsPath!)
            do {
                try FileManager.default.createDirectory(atPath: logsPath!.path, withIntermediateDirectories: true, attributes: nil)
                
                finalPath = logsPath
                
            } catch let error as NSError {
                NSLog("Unable to create directory \(error.debugDescription)")
            }
        }
        print(finalPath?.path ?? "")

    }
}

extension AVAsset {
    
    func writeAudioTrackToURL(_ url: URL, completion: @escaping (Bool, Error?) -> ()) {
        do {
            let audioAsset = try self.audioAsset()
            audioAsset.writeToURL(url, completion: completion)
        } catch (let error as NSError){
            completion(false, error)
        }
    }
    
    func writeToURL(_ url: URL, completion: @escaping (Bool, Error?) -> ()) {
        
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetAppleM4A) else {
            completion(false, nil)
            return
        }
        
        exportSession.outputFileType = .m4a
        exportSession.outputURL = url
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(true, nil)
            case .unknown, .waiting, .exporting, .failed, .cancelled:
                completion(false, nil)
            @unknown default:
                completion(false, nil)
            }
        }
    }
    
    func audioAsset() throws -> AVAsset {
        
        let composition = AVMutableComposition()
        let audioTracks = tracks(withMediaType: .audio)
        
        for track in audioTracks {
            
            let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try compositionTrack?.insertTimeRange(track.timeRange, of: track, at: track.timeRange.start)
            compositionTrack?.preferredTransform = track.preferredTransform
        }
        return composition
    }
}

extension UINavigationBar
{
    /// Applies a background gradient with the given colors
    func applyNavigationGradient( colors : [UIColor]) {
        var frameAndStatusBar: CGRect = self.bounds
        frameAndStatusBar.size.height += 20 // add 20 to account for the status bar
        
        setBackgroundImage(UINavigationBar.gradient(size: frameAndStatusBar.size, colors: colors), for: .default)
    }
    
    /// Creates a gradient image with the given settings
    static func gradient(size : CGSize, colors : [UIColor]) -> UIImage?
    {
        // Turn the colors into CGColors
        let cgcolors = colors.map { $0.cgColor }
        
        // Begin the graphics context
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        
        // If no context was retrieved, then it failed
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // From now on, the context gets ended if any return happens
        defer { UIGraphicsEndImageContext() }
        
        // Create the Coregraphics gradient
        var locations : [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgcolors as NSArray as CFArray, locations: &locations) else { return nil }
        
        // Draw the gradient
        context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: size.width, y: 0.0), options: [])
        
        // Generate the image (the defer takes care of closing the context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension HomeViewController: AVCaptureFileOutputRecordingDelegate{
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print(outputFileURL)
        
        if (error != nil) {
            print("Error recording movie: \(error!.localizedDescription)")
        } else if let videoRecorded = outputURL{
            if self.currentFeature == .slowFastVideo{
                let objSlowFastVideoVC = StoryBoards.objSlowFastVideoViewController.instantiateViewController(withIdentifier: "SlowFastVideoViewController")as! SlowFastVideoViewController
                objSlowFastVideoVC.objVideoAsset = AVAsset(url: videoRecorded)
                objSlowFastVideoVC.screenTitle = self.arrFunctionalities[self.currentIndex].name
                self.navigationController?.pushViewController(objSlowFastVideoVC, animated: true)
            }else if self.currentFeature == .watermarkVideo{
                let objWatermarkVideoVC = StoryBoards.objWatermarkVideoViewController.instantiateViewController(withIdentifier: "WatermarkVideoViewController")as! WatermarkVideoViewController
                objWatermarkVideoVC.objVideoAsset = AVAsset(url: videoRecorded)
                objWatermarkVideoVC.screenTitle = self.arrFunctionalities[self.currentIndex].name
                self.navigationController?.pushViewController(objWatermarkVideoVC, animated: true)
            }else if self.currentFeature == .videoFilter{
                let objVUVideoFilterVC = StoryBoards.objVideoFilterViewController.instantiateViewController(withIdentifier: "VUVideoFilterVC")as! VUVideoFilterVC
                objVUVideoFilterVC.objVideoAsset = AVAsset(url: videoRecorded)
                objVUVideoFilterVC.screenTitle = self.arrFunctionalities[self.currentIndex].name
                self.navigationController?.pushViewController(objVUVideoFilterVC, animated: true)
            }else if self.currentFeature == .reverseVideo{
                let objReverseVideoViewController = StoryBoards.objReverseVideoViewController.instantiateViewController(withIdentifier: "ReverseVideoViewController")as! ReverseVideoViewController
                objReverseVideoViewController.objVideoAsset = AVAsset(url: videoRecorded)
                objReverseVideoViewController.screenTitle = self.arrFunctionalities[self.currentIndex].name
                self.navigationController?.pushViewController(objReverseVideoViewController, animated: true)
            }else{
                let objTrimmerVC = StoryBoards.objTrimmerViewController.instantiateViewController(withIdentifier: "TrimmerViewController")as! TrimmerViewController
                objTrimmerVC.videoURL = videoRecorded
                objTrimmerVC.objVideoAsset = AVAsset(url: videoRecorded)
                objTrimmerVC.currentFeature = self.currentFeature
                objTrimmerVC.screenTitle = self.arrFunctionalities[self.currentIndex].name
                self.onPressCancelVideoCapture()
                self.navigationController?.pushViewController(objTrimmerVC, animated: true)
            }
        }
    }
}

extension HomeViewController: AssetsPickerViewControllerDelegate {
    public func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
        var arrAVAssets:[AVAsset]=[]
        let videoOptions = PHVideoRequestOptions()
        videoOptions.isNetworkAccessAllowed = true
        HUD.show(.systemActivity)
        var i : Int = 0
        for asset in assets{
            let semaphore = DispatchSemaphore(value: 0)
            PHImageManager.default().requestAVAsset(forVideo: asset, options: videoOptions) { avAsset, _, _ in
                if let finalAsset = avAsset{
                    arrAVAssets.append(finalAsset)
                    semaphore.signal()
                    if i == (assets.count - 1){
                        DispatchQueue.main.async {
                            HUD.hide()
                            let objMergeVideoViewController = StoryBoards.objMergeVideoViewController.instantiateViewController(withIdentifier: "MergeVideoViewController")as! MergeVideoViewController
                            objMergeVideoViewController.arrSelectedVideosList = arrAVAssets
                            objMergeVideoViewController.screenTitle = self.arrFunctionalities[self.currentIndex].name
                            self.navigationController?.pushViewController(objMergeVideoViewController, animated: true)
                        }
                    }
                    i = i + 1
                }
            }
            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }
    
    public func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        if (controller.selectedAssets.count == maxVideoSelection){
            return false
        }else{
            return true
        }
    }
}
