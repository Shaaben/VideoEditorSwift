//
//  SaveItemCollectionViewController.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import UIKit
import AVFoundation
import SDWebImage

class SaveItemCollectionViewController: UIViewController{
    
    //Mark:-Outlet
    @IBOutlet weak var previewImgView: UIView!
    @IBOutlet weak var previewSaveItemImageView: UIImageView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noDataPromptLabel: UILabel!


    @IBOutlet var editBtn: UIButton!
    @IBOutlet var deleteBtn: UIButton!

    @IBOutlet var heightOfViewEditingBtns: NSLayoutConstraint!
    
    var arrURLs:[URL] = []
    var collectionAudioURL = [SaveItemCollectionModel]()
    var audioPlayer: AVAudioPlayer?
    var currentSaveFeature:SaveAppFeatures!
    var currentIndexpath:IndexPath!
    var videoPlayer: AVPlayer?
    var dateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = currentSaveFeature.map { $0.rawValue }
        previewImgView.alpha = 0.0
        previewImgView.isHidden = true
        
        switch currentSaveFeature{
        case SaveAppFeatures.GIF?:
            getGifFromDirectory()
        case SaveAppFeatures.Audio?:
            getAudioFromDirectory()
        case SaveAppFeatures.Images?:
            getImagesFromDirectory()
        case SaveAppFeatures.Video?:
            getVideosFromDirectory()
        default:
            print("No AppFeatures Get")
        }
        
        tableView.tableFooterView = UIView()
        addEditBtnToNavBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        loadInterstitialAd()
    }
    
    @IBAction func closeBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
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
    
    func addEditBtnToNavBar(){
        if currentSaveFeature == SaveAppFeatures.Audio {
            if collectionAudioURL.count > 0{
                let item = UIBarButtonItem(customView: editBtn)
                self.navigationItem.setRightBarButtonItems([item], animated: true)
            }
        }else{
            if arrURLs.count > 0 {
                editBtn.isHidden = false
                let item = UIBarButtonItem(customView: editBtn)
                self.navigationItem.setRightBarButtonItems([item], animated: true)
            }
        }
        showHideEditingBtns()
    }
    
    func showHideEditingBtns(){
        var showEditingBtns = false
        if currentSaveFeature == SaveAppFeatures.Audio {
            if collectionAudioURL.count > 0 &&  editBtn.isSelected {
                showEditingBtns = true
            }
        }else{
            if arrURLs.count > 0 && editBtn.isSelected{
                showEditingBtns = true
            }
        }
        if showEditingBtns {
            UIView.animate(withDuration: 0.3) {
                self.heightOfViewEditingBtns.constant = 50
            }
            editBtn.isHidden = false
        }else{
            UIView.animate(withDuration: 0.3) {
                self.heightOfViewEditingBtns.constant = 0
                self.deleteBtn.isHidden = true
            }
            editBtn.isHidden = true
        }
        
        if currentSaveFeature == SaveAppFeatures.Audio {
            if collectionAudioURL.count > 0{
                noDataPromptLabel.isHidden = true
            }else{
                noDataPromptLabel.isHidden = false
            }
        }else{
            if arrURLs.count > 0 {
                noDataPromptLabel.isHidden = true
            }else{
                noDataPromptLabel.isHidden = false
            }
        }
        
        if currentSaveFeature == .Audio{
            noDataPromptLabel.text = "No Audio Found"
        }else if currentSaveFeature == .GIF{
            noDataPromptLabel.text = "No GIF Found"
        }else if currentSaveFeature == .Images{
            noDataPromptLabel.text = "No Image Found"
        }else if currentSaveFeature == .Video{
            noDataPromptLabel.text = "No Video Found"
        }
    }
    
    //MARK:Actions
    @IBAction func btnCancelPreview(_ sender: UIButton) {
        showDetailPopup(isVisible: false)
        audioPlayer?.stop()
        videoPlayer?.pause()
    }
    
    @IBAction func btnForSharePreview(_ sender: UIButton) {
        perforShareActions()
    }
    
    func perforShareActions(){
        switch currentSaveFeature{
        case SaveAppFeatures.Audio?:
            shareCurrentData(shareDataArrayname: collectionAudioURL)
        default:
            shareCurrentData(shareDataArrayname: arrURLs)
        }
    }
    
    func shareCurrentData(shareDataArrayname:Array<Any>){
        let activityController = UIActivityViewController(activityItems: [shareDataArrayname[currentIndexpath.row]], applicationActivities: nil)
        self.present(activityController, animated: true, completion: nil)
    }
    
    func getGifFromDirectory() {
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsURL.appendingPathComponent(Directories.GIF.rawValue)
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            self.arrURLs = fileURLs
            self.tableView.reloadData()
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }
    
    func getAudioFromDirectory(){
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsURL.appendingPathComponent(Directories.Audio.rawValue)
        print(documentsURL)
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for url in fileURLs {
                let model = SaveItemCollectionModel.init()
                model.url = url
                self.collectionAudioURL.append(model)
                self.tableView.reloadData()
            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }
    
    func getImagesFromDirectory(){
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsURL.appendingPathComponent(Directories.Image.rawValue)
        print(documentsURL)
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            self.arrURLs = fileURLs
            self.tableView.reloadData()
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }
    
    func getVideosFromDirectory(){
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsURL.appendingPathComponent(Directories.Video.rawValue)
        print(documentsURL)
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            self.arrURLs = fileURLs
            self.tableView.reloadData()
            // process files
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }

    func playUsingAVAudioPlayer(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.m4a.rawValue)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print(error)
        }
    }
    
    func pauseUsingAVAudioPlayer() {
        audioPlayer?.stop()
    }

    func shareContent(shareItemIndex:IndexPath){
        let activityController = UIActivityViewController(activityItems: [shareItemIndex], applicationActivities: nil)
        self.present(activityController, animated: true, completion: nil)
    }
        
    private func addVideoPlayer(with url: URL, playerView: UIView) {
        playerView.layer.sublayers?.removeAll()
        let playerItem = AVPlayerItem(url: url)
        videoPlayer = AVPlayer(playerItem: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(SaveItemCollectionViewController.itemDidFinishPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        let layer: AVPlayerLayer = AVPlayerLayer(player: videoPlayer)
        layer.backgroundColor = UIColor.clear.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
        layer.videoGravity = AVLayerVideoGravity.resizeAspect
        playerView.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        playerView.layer.addSublayer(layer)
        videoPlayer?.play()
    }
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        self.videoPlayer?.seek(to: CMTime.zero)
        self.videoPlayer?.play()
    }
    
    func showDetailPopup(isVisible:Bool = true){
        if isVisible{
            previewImgView.isHidden = false
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            if isVisible{
                self.previewImgView.alpha = 1.0
            }else{
                self.previewImgView.alpha = 0.0
            }
            self.previewImgView.layoutIfNeeded()
        }) { (complete) in
            if !isVisible{
                self.previewImgView.isHidden = true
            }
        }
    }
    
    @IBAction func onPressEdit(_ sender: UIButton?) {
        if editBtn.isSelected {
            editBtn.isSelected = false
            tableView.setEditing(false, animated: true)
            tableView.reloadData()
            deleteBtn.isHidden = true
        }else{
            editBtn.isSelected = true
            editBtn.setTitle("Cancel", for: .selected)
            tableView.setEditing(true, animated: true)
            tableView.reloadData()
            deleteBtn.isHidden = false
        }
        showHideEditingBtns()
    }
    
    @IBAction func onPressDeleteAll(_ sender: UIButton) {
        var urlToDelete:URL?
        if self.currentSaveFeature == .Audio{
            for objAudio in collectionAudioURL{
                let index:Int = collectionAudioURL.firstIndex(of: objAudio)!
                let objAudio = self.collectionAudioURL[index]
                urlToDelete = objAudio.url
                self.collectionAudioURL.remove(at: index)
                try? FileManager.default.removeItem(at: urlToDelete!)
            }
        } else {
            for obj in arrURLs {
                let index:Int = arrURLs.firstIndex(of: obj)!
                urlToDelete = self.arrURLs[index]
                self.arrURLs.remove(at: index)
                try? FileManager.default.removeItem(at: urlToDelete!)
            }
        }
        onPressEdit(nil)
        self.tableView.reloadData()
    }
}

extension SaveItemCollectionViewController: AVAudioPlayerDelegate{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        clickedPlayPauseButtonAtIndexPath(indexPath: currentIndexpath)
    }
}

extension SaveItemCollectionViewController:SaveItemCellDelegate{
    func shareData(activityController: UIActivityViewController) {
        self.present(activityController, animated: true, completion: nil)
    }
    
    func clickedShareButtonAtIndexPath(indexPath: IndexPath) {
        currentIndexpath = indexPath
        perforShareActions()
    }
    
    func clickedPlayPauseButtonAtIndexPath(indexPath: IndexPath) {
        if currentIndexpath == nil{
            currentIndexpath = indexPath
        }
        
        if currentIndexpath.row != indexPath.row {
            var prevModel = SaveItemCollectionModel.init()
            prevModel = collectionAudioURL[currentIndexpath.row]
            prevModel.isSelected = false
            collectionAudioURL[currentIndexpath.row] = prevModel
            tableView.reloadRows(at: [currentIndexpath], with: .automatic)
        }
        
        var model = SaveItemCollectionModel.init()
        currentIndexpath = indexPath
        model = collectionAudioURL[currentIndexpath.row]
        if model.isSelected{
            model.isSelected = false
            pauseUsingAVAudioPlayer()
        }else{
            model.isSelected = true
            playUsingAVAudioPlayer(url: model.url!)
        }
        collectionAudioURL[currentIndexpath.row] = model
        tableView.reloadRows(at: [currentIndexpath], with: .automatic)
    }
}

// MARK:- UITableViewDataSource and UITableViewDelegate Methods
extension SaveItemCollectionViewController: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowCount = 0
        if currentSaveFeature == .Audio{
            rowCount = collectionAudioURL.count
        }else if currentSaveFeature == .GIF{
            rowCount = arrURLs.count
        }else if currentSaveFeature == .Images{
            rowCount = arrURLs.count
        }else if currentSaveFeature == .Video{
            rowCount = arrURLs.count
        }
        
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifer = "GalleryItemCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifer) as! GalleryItemCell
        cell.dateFormatter = self.dateFormatter
        cell.selectionStyle = .none
        
        if currentSaveFeature == .Audio{
            cell.configureWithItem(collectionAudioURL[indexPath.row])
        } else {
            cell.configureWithItem(arrURLs[indexPath.row], currentFeature: currentSaveFeature)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch currentSaveFeature{
        case SaveAppFeatures.GIF?:
            let data = try? Data(contentsOf: arrURLs[indexPath.row])
            let imageURL = UIImage.sd_animatedGIF(with: data)
            previewSaveItemImageView.image = imageURL
            currentIndexpath = indexPath
            self.showDetailPopup()
            break
        case SaveAppFeatures.Images?:
            let data = try? Data(contentsOf: arrURLs[indexPath.row])
            let imageURL = UIImage.sd_animatedGIF(with: data)
            previewSaveItemImageView.image = imageURL
            currentIndexpath = indexPath
            self.showDetailPopup()
            break
        case SaveAppFeatures.Video?:
            previewSaveItemImageView.isHidden = true
            playerView.isHidden = false
            addVideoPlayer(with: arrURLs[indexPath.row], playerView: playerView)
            currentIndexpath = indexPath
            self.showDetailPopup()
            break
        case .Audio?:
            currentIndexpath = indexPath
            previewSaveItemImageView.isHidden = false
            let bundle = Bundle(for: type(of:self))
            previewSaveItemImageView.image = UIImage(named: "music-player", in: bundle, compatibleWith: nil)!
            self.playUsingAVAudioPlayer(url: collectionAudioURL[indexPath.row].url!)
            self.showDetailPopup()
            break
        default:
            print("no data found")
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if tableView.isEditing {
            let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indxPath) in
                var urlToDelete:URL?
                if self.currentSaveFeature == .Audio{
                    let objAudio = self.collectionAudioURL[indexPath.row]
                    urlToDelete = objAudio.url
                    self.collectionAudioURL.remove(at: indxPath.row)
                } else {
                    urlToDelete = self.arrURLs[indxPath.row]
                    self.arrURLs.remove(at: indxPath.row)
                }
                try? FileManager.default.removeItem(at: urlToDelete!)
                self.tableView.reloadData()
                self.showHideEditingBtns()
            }
            return [deleteAction]
        }else{
            return []
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
