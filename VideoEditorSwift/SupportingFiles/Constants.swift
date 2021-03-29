//
//  Constants.swift
//  ProjectStructure
//
//  Created by sandip on 10/2/18.
//  Copyright © 2018 Elsner Technologies. All rights reserved.
//

import Foundation
import UIKit

let maxScreenTraverse = 5
var totalScreenTraverse = 0

public struct StoryBoards
{
    class Bar {}
    static var bundle: Bundle { return Bundle(for: StoryBoards.Bar.self) }
    static  let objHomeSB = UIStoryboard(name: "HomeViewController", bundle: bundle)
    static  let objSaveItemGallerySB = UIStoryboard(name: "SaveItemGalleryViewController", bundle: bundle)
    static  let objTrimmerViewController = UIStoryboard(name: "TrimmerViewController", bundle: bundle)
    static  let objSaveItemCollectionViewController = UIStoryboard(name: "SaveItemCollectionViewController", bundle: bundle)
    static  let objSlowFastVideoViewController = UIStoryboard(name: "SlowFastVideoViewController", bundle: bundle)
    static  let objWatermarkVideoViewController = UIStoryboard(name: "WatermarkVideoViewController", bundle: bundle)
    static  let objVideoFilterViewController = UIStoryboard(name: "VideoFilterViewController", bundle: bundle)
    static  let objReverseVideoViewController = UIStoryboard(name: "ReverseVideoViewController", bundle: bundle)
    static  let objMergeVideoViewController = UIStoryboard(name: "MergeVideoViewController", bundle: bundle)
}

public enum Directories: String{
    case GIF,Audio,Video,Image
    
    static func prefixForDirectory(_ directory:Directories) -> String {
        var prefix = ""
        switch directory {
        case .GIF:
            prefix = "GIF_"
            break
        case .Audio:
            prefix = "AUD_"
            break
        case .Video:
            prefix = "VID_"
            break
        case .Image:
            prefix = "IMG_"
            break
        }
        return prefix
    }
}

public enum AppFeatures:String{
    case videoToGIF, imagesToGIF, videoToAudio, videoCutter, captureImage, slowFastVideo, watermarkVideo, videoFilter, reverseVideo, mergeVideo
}

struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
        isSim = true
        #endif
        return isSim
    }()
}

public struct Color {
    static let fontColor = "#555555"
    static let themeColor = "#EFEFF4"
}

public struct InAppProducts {
    public static let proVersion = "<Proversion ID>"
    public static let sharedSecret="<Shared Secret>"
}

class AppConfig {
    public static var APPID = "";
    public static var SHARE_TEXT = "";
    static let privacyURL: URL = URL(string: "http://google.com/")!
    static let termsURL: URL = URL(string: "http://google.com/")!
    public static let adsDisplayInterval = 2
    public static let moreapp = "http://google.com/"

    
   
}

struct GoogleAdsUnitID {
    struct Live {
        static var isAdmobAds = "false"
        static let appId = "ca-app-pub-9658650820455367~1564591515"
        static var strBannerAdsID = "ca-app-pub-3940256099942544/6300978111"
        static var strInterstitialAdsID = "ca-app-pub-3940256099942544/1033173712"
        static var strNativeAdsID = "ca-app-pub-3940256099942544/2247696110"
    }
}

struct FacebookUnit {
    struct Live {
        static var isFbAds = "true"
        static var fbBannerId = "YOUR_PLACEMENT_ID" //"YOUR_PLACEMENT_ID"//
        static var fbInterstitialId = "YOUR_PLACEMENT_ID" //"YOUR_PLACEMENT_ID"
        static var fbNativeBannerId = "YOUR_PLACEMENT_ID" //"YOUR_PLACEMENT_ID"
        static var fbNativeId = "YOUR_PLACEMENT_ID" //"YOUR_PLACEMENT_ID
    }
}

struct BtnLayout {
    static let btnColor = #colorLiteral(red: 0.06666666667, green: 0.1137254902, blue: 0.1843137255, alpha: 1)
      static let btnColor_2 = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
    static let btnRadius:CGFloat = 16.0
    static let btnBorderColor:CGColor = #colorLiteral(red: 0.1921568662, green: 0.007843137719, blue: 0.09019608051, alpha: 1)
    static let btnBorderWidth:CGFloat = 1.0
    
}

struct UserdefultConfig {
    public static var isAdsFree = "isAdsFree"
    public static var isFbads = "isFbads"
    public static var fbBannerAds = "fbBannerAds"
    public static var fbInterstitialAds = "fbInterstitialAds"
    public static var fbNativeBannerAds = "fbNativeBannerAds"
    public static var fbNativeAds = "fbNativeAds"
    public static var isAdmobAds = "isAdmobAds"
    public static var admobBannerAds = "admobBannerAds"
    public static var admobInterstitialAds = "admobInterstitialAds"
    public static var admobNativeAds = "admobNativeAds"
}


