//
//  SaveItemGalleryViewController.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import UIKit

public enum SaveAppFeatures:String{
    case GIF, Audio, Images ,Video
}

class SaveItemGalleryViewController: UIViewController {
    
    var arrFunctionalities:[Functionalities] = []
    var currentSaveFeature:SaveAppFeatures!
    var dateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Gallery"
        let bundle = Bundle(for: type(of:self))
        arrFunctionalities.append(Functionalities(name: "GIF", imgIcon: UIImage(named: "gif", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "Audio", imgIcon: UIImage(named: "audio", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "Video", imgIcon: UIImage(named: "video", in: bundle, compatibleWith: nil)!))
        arrFunctionalities.append(Functionalities(name: "Images", imgIcon: UIImage(named: "Image", in: bundle, compatibleWith: nil)!))
    }
    
    @IBAction func closeAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        loadInterstitialAd()
    }

    func shareContent(){
        //            let activityController = UIActivityViewController(activityItems: [collectionGif[indexPath.row]], applicationActivities: nil)
        //            self.present(activityController, animated: true, completion: nil)
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
}
extension SaveItemGalleryViewController:UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrFunctionalities.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let objSaveItemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "SaveItemGalleryCell", for: indexPath)as! SaveItemGalleryCell
        //        let data = try? Data(contentsOf: collectionGif[indexPath.row])
        //        objSaveItemCell.imgViewForSavingItems.image = UIImage(data: data!)
        
        objSaveItemCell.lblForSaveFunctionalityName.text = arrFunctionalities[indexPath.row].name
        
        objSaveItemCell.imgForUtilityIcon.image = arrFunctionalities[indexPath.row].imgIcon
        
        return objSaveItemCell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0{
            let objSaveItemCollectionViewController = StoryBoards.objSaveItemCollectionViewController.instantiateViewController(withIdentifier: "SaveItemCollectionViewController")as! SaveItemCollectionViewController
            objSaveItemCollectionViewController.currentSaveFeature = SaveAppFeatures.GIF
            objSaveItemCollectionViewController.dateFormatter = self.dateFormatter
            self.navigationController?.pushViewController(objSaveItemCollectionViewController, animated: true)
            
        }else if indexPath.row == 1{
            
            let objSaveItemCollectionViewController = StoryBoards.objSaveItemCollectionViewController.instantiateViewController(withIdentifier: "SaveItemCollectionViewController")as! SaveItemCollectionViewController
            objSaveItemCollectionViewController.currentSaveFeature = SaveAppFeatures.Audio
            objSaveItemCollectionViewController.dateFormatter = self.dateFormatter
            self.navigationController?.pushViewController(objSaveItemCollectionViewController, animated: true)
            
        }else if indexPath.row == 2{
            let objSaveItemCollectionViewController = StoryBoards.objSaveItemCollectionViewController.instantiateViewController(withIdentifier: "SaveItemCollectionViewController")as! SaveItemCollectionViewController
            objSaveItemCollectionViewController.currentSaveFeature = SaveAppFeatures.Video
            objSaveItemCollectionViewController.dateFormatter = self.dateFormatter
            self.navigationController?.pushViewController(objSaveItemCollectionViewController, animated: true)

        }else if indexPath.row == 3{
            let objSaveItemCollectionViewController = StoryBoards.objSaveItemCollectionViewController.instantiateViewController(withIdentifier: "SaveItemCollectionViewController")as! SaveItemCollectionViewController
            objSaveItemCollectionViewController.currentSaveFeature = SaveAppFeatures.Images
            objSaveItemCollectionViewController.dateFormatter = self.dateFormatter
            self.navigationController?.pushViewController(objSaveItemCollectionViewController, animated: true)
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let yourWidth = collectionView.bounds.width/2
        let yourHeight = yourWidth
        
        return CGSize(width: yourWidth, height: yourHeight)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}
