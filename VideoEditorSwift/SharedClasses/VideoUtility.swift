//
//  VideoUtility.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import Foundation
import UIKit
import Regift
import AVFoundation
import PryntTrimmerView
import MobileCoreServices
import AssetsLibrary
import Photos
import AVKit
import PKHUD

let gifFrameRate = 15
let maxVideoSelection = 5

enum Result<T> {
    case Success(T)
    case Error(String)
}

enum SpeedoMode:Int {
    case Slower
    case Faster
}

enum ScaleFactor:Int64 {
    case normal = 1
    case medium = 2
    case maximum = 3
}

enum QUWatermarkPosition {
    case TopLeft
    case TopRight
    case BottomLeft
    case BottomRight
    case Default
}

enum VideoQuality:String {
    case AVAssetExportPresetLowQuality
    case AVAssetExportPresetMediumQuality
    case AVAssetExportPresetHighestQuality
}

class VideoUtility: NSObject {
    
    static let shared = VideoUtility()
    let fileManager = FileManager.default
    
    func convertImagesToGIF(with images: [UIImage], loopCount: Int = 2, frameDelay: Double, completion: ((Result<Data>) -> Void)?) {
        
        createIfNotExist(directory: .GIF)
        guard let finalPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(Directories.GIF.rawValue + "/\(Directories.prefixForDirectory(.GIF))" + String(Date().timeIntervalSince1970) + ".gif") else {
            completion?(.Error("Could not generate final path to save gif."))
            return
        }
        
        guard let destinationGIF = CGImageDestinationCreateWithURL(finalPath as CFURL, kUTTypeGIF, images.count, nil) else {
            completion?(.Error("Failed to generate the final GIF"))
            return
        }
        
        let properties = [
            (kCGImagePropertyGIFDictionary as String): [(kCGImagePropertyGIFDelayTime as String): frameDelay, (kCGImagePropertyGIFLoopCount as String): loopCount]
        ]
        
        for img in images {
            let inputImage = CIImage(image: img, options: nil)!
            let cgImage = CIContext(options: nil).createCGImage(inputImage, from: inputImage.extent)
            CGImageDestinationAddImage(destinationGIF, cgImage!, properties as CFDictionary)
        }
        
        // Write the GIF file to disk
        CGImageDestinationFinalize(destinationGIF)
        let finalData = try! Data(contentsOf: finalPath)
        completion?(.Success(finalData))
    }
    
    func convertVideoToGif(_ videoURL:URL, startTime:Float, duration:Float, loopCount: Int = 2, completion: ((Result<URL>) -> Void)?){
        
        self.createIfNotExist(directory: .GIF)
        guard let finalPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(Directories.GIF.rawValue + "/\(Directories.prefixForDirectory(.GIF))" + String(Date().timeIntervalSince1970) + ".gif") else {
            completion?(.Error("Could not generate final path to save gif."))
            return
        }

        let trimmedRegift = Regift(sourceFileURL: videoURL, startTime: startTime, duration: duration, frameRate: gifFrameRate, loopCount: loopCount)
        guard let destinationURL = trimmedRegift.createGif() else {
            completion?(.Error("Failed to generate the final GIF"))
            return
        }
        
        do {
            if !fileManager.fileExists(atPath: (finalPath.path)) {
                try fileManager.copyItem(at: destinationURL, to: finalPath)
                clearTempFolder()
            }
            completion?(.Success(finalPath))
        } catch {
            completion?(.Error(error.localizedDescription))
        }
    }

    func convertVideoToAudio(_ asset:AVAsset, startTime:CMTime, duration:CMTime, completion: ((Result<URL>) -> Void)?){
        
        guard let srcTrack = asset.tracks(withMediaType: AVMediaType.audio).first else {
            completion?(.Error("Could not find audio track in the video"))
            return
        }

        let newAudioAsset = AVMutableComposition()
        guard let newCompositionTrack = newAudioAsset.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion?(.Error("Could not add audio track to the new composition track"))
            return
        }

        let trackTimeRange = CMTimeRangeMake(start: startTime, duration: duration)
        let tempUrl = URL(fileURLWithPath: "\(NSTemporaryDirectory())TrimmedAudio.m4a")
        try? FileManager.default.removeItem(at: tempUrl)
        
        createIfNotExist(directory: .Audio)
        guard let finalPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(Directories.Audio.rawValue + "/\(Directories.prefixForDirectory(.Audio))" + String(Date().timeIntervalSince1970) + ".m4a") else {
            completion?(.Error("Could not generate final path to save audio."))
            return
        }

        do {
            try newCompositionTrack.insertTimeRange(trackTimeRange, of: srcTrack, at: CMTime.zero)
            let exportSession = AVAssetExportSession(asset: newAudioAsset, presetName: AVAssetExportPresetPassthrough)
            exportSession?.outputFileType = AVFileType.m4a
            exportSession?.outputURL = tempUrl
            exportSession?.exportAsynchronously(completionHandler: {
                guard let audioURL = exportSession?.outputURL, exportSession?.status == .completed else {
                    completion?(.Error((exportSession?.error?.localizedDescription)!))
                    return
                }

                do {
                    if !self.fileManager.fileExists(atPath: (finalPath.path)) {
                        try self.fileManager.copyItem(at:audioURL, to: finalPath)
                        self.clearTempFolder()
                        completion?(.Success(finalPath))
                    }
                } catch {
                    completion?(.Error(error.localizedDescription))
                }
            })
        } catch {
            print(error.localizedDescription)
            completion?(.Error(error.localizedDescription))
        }
    }

    func trimVideo(_ asset:AVAsset, startTime:CMTime, duration:CMTime, completion: ((Result<URL>) -> Void)?) {
        
        guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            completion?(.Error("Could not find audio track in the video"))
            return
        }
        
        let assetComposition = AVMutableComposition()
        let trackTimeRange = CMTimeRangeMake(start: startTime, duration: duration)
        
        guard let videoCompositionTrack = assetComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion?(.Error("Could not add audio track to the new composition track"))
            return
        }

        do{
            try videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: CMTime.zero)
            if let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first {
                let audioCompositionTrack = assetComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                try audioCompositionTrack?.insertTimeRange(trackTimeRange, of: audioTrack, at: CMTime.zero)
            }
            
            //1. Create the instructions
            let mainInstructions = AVMutableVideoCompositionInstruction()
            mainInstructions.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
            
            //2 add the layer instructions
            let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
            var renderSize = videoTrack.naturalSize
            layerInstructions.setTransform(videoTrack.preferredTransform, at: CMTime.zero)
            if isVideoPortrait(asset: asset) {
                renderSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
            }
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
                    guard let videoURL = exportSession?.outputURL, exportSession?.status == .completed else {
                        completion?(.Error((exportSession?.error?.localizedDescription)!))
                        return
                    }
                    
                    self.createIfNotExist(directory: .Video)
                    guard let finalPath = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(Directories.Video.rawValue + "/\(Directories.prefixForDirectory(.Video))" + String(Date().timeIntervalSince1970) + "." + tempUrl.pathExtension) else {
                        completion?(.Error("Could not generate final path to save audio."))
                        return
                    }
                    
                    do {
                        if !self.fileManager.fileExists(atPath: (finalPath.path)) {
                            try self.fileManager.copyItem(at:videoURL, to: finalPath)
                            self.clearTempFolder()
                            completion?(.Success(finalPath))
                        }
                    } catch {
                        completion?(.Error(error.localizedDescription))
                    }
                }
            })
        }catch{
            completion?(.Error(error.localizedDescription))
        }
    }
    
    func isVideoPortrait(asset:AVAsset)->Bool{
        var isPortrait:Bool = false
        let tracks = asset.tracks(withMediaType: .video)
        if tracks.count > 0 {
            let videoTrack = tracks.first
            let t:CGAffineTransform = (videoTrack?.preferredTransform)!
            // Portrait
            if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
            {
                isPortrait = true
            }
            // PortraitUpsideDown
            if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)  {
                
                isPortrait = true
            }
            // LandscapeRight
            if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0)
            {
                isPortrait = false
            }
            // LandscapeLeft
            if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
            {
                isPortrait = false
            }
        }
        return isPortrait
    }
    
    /// Range is b/w 1x, 2x and 3x. Will not happen anything if scale is out of range. Exporter will be nil in case url is invalid or unable to make asset instance.
    func scaleAsset(by scale: ScaleFactor, withMode mode: SpeedoMode,_ asset:AVAsset,startTime:CMTime, duration:CMTime, completion: ((Result<URL>) -> Void)?){
        
        /// Check the valid scale
        if scale.rawValue < 1 || scale.rawValue > 3 {
            /// Can not proceed, Invalid range
        }
        
        /// Video Tracks
        let videoTracks = asset.tracks(withMediaType: AVMediaType.video)
        if videoTracks.count == 0 {
            /// Can not find any video track
        }
        
        /// Get the scaled video duration
        let scaledVideoDuration = (mode == .Faster) ? CMTimeMake(value: asset.duration.value / scale.rawValue, timescale: asset.duration.timescale) : CMTimeMake(value: asset.duration.value * scale.rawValue, timescale: asset.duration.timescale)
        let timeRange = CMTimeRangeMake(start: startTime, duration: duration)
        
        /// Video track
        let videoTrack = videoTracks.first!
        
        let mixComposition = AVMutableComposition()
        let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        /// Audio Tracks
//        let audioTracks = asset.tracks(withMediaType: AVMediaType.audio)
//        if audioTracks.count > 0 {
//            /// Use audio if video contains the audio track
//            let compositionAudioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
//            
//            /// Audio track
//            let audioTrack = audioTracks.first!
//            do {
//                try compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: CMTime.zero)
//                compositionAudioTrack?.scaleTimeRange(timeRange, toDuration: scaledVideoDuration)
//            } catch _ {
//                /// Ignore audio error
//            }
//        }
        
        do {
            try compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: CMTime.zero)
            compositionVideoTrack?.scaleTimeRange(timeRange, toDuration: scaledVideoDuration)
            
            /// Keep original transformation
            compositionVideoTrack?.preferredTransform = videoTrack.preferredTransform
            
            /// Initialize Exporter now
            let tempUrl = URL(fileURLWithPath: "\(NSTemporaryDirectory())TrimmedMovie.mov")
            /// Note:- Please use directory path if you are testing with device.
            
            if FileManager.default.fileExists(atPath: tempUrl.absoluteString) {
                try FileManager.default.removeItem(at: tempUrl)
            }
            
            let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
            exporter?.outputURL = tempUrl
            exporter?.outputFileType = AVFileType.mov
            exporter?.shouldOptimizeForNetworkUse = true
            exporter?.exportAsynchronously(completionHandler: {
                DispatchQueue.main.async {
                    guard let videoURL = exporter?.outputURL, exporter?.status == .completed else {
                        completion!(.Error((exporter?.error?.localizedDescription)!))
                        return
                    }
                    
                    self.createIfNotExist(directory: .Video)
                    guard let finalPath = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(Directories.Video.rawValue + "/\(Directories.prefixForDirectory(.Video))" + String(Date().timeIntervalSince1970) + "." + tempUrl.pathExtension) else {
                        completion?(.Error("Could not generate final path to save audio."))
                        return
                    }
                    
                    do {
                        if !self.fileManager.fileExists(atPath: (finalPath.path)) {
                            try self.fileManager.copyItem(at:videoURL, to: finalPath)
                            self.clearTempFolder()
                            completion?(.Success(finalPath))
                        }
                    } catch {
                        completion?(.Error(error.localizedDescription))
                    }
                }            })
            
        } catch let error {
            print(error.localizedDescription)
            completion?(.Error(error.localizedDescription))
            return
        }
    }

    func captureImageFromVideo(asset: AVAsset, selectedTime:CMTime, completion: ((Result<URL>) -> Void)?){
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = CMTime.zero
        generator.requestedTimeToleranceAfter = CMTime.zero
        generator.appliesPreferredTrackTransform = true
        var actualTime = CMTime.zero
        
        guard let image = try? generator.copyCGImage(at: selectedTime, actualTime: &actualTime) else {
            completion?(.Error("Failed to generate the final Image"))
            return
        }

        createIfNotExist(directory: .Image)
        guard let finalPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(Directories.Image.rawValue + "/\(Directories.prefixForDirectory(.Image))" + String(Date().timeIntervalSince1970) + ".jpg") else {
            completion?(.Error("Could not generate final path to save audio."))
            return
        }

        let selectedImage = UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .up)
        guard let data = selectedImage.jpegData(compressionQuality: 1.0), !fileManager.fileExists(atPath: (finalPath.path)) else {
            completion?(.Error("Error in generating image data from the Image"))
            return
        }
        
        do {
            try data.write(to: finalPath)
        } catch {
            completion?(.Error("error saving file: \(error.localizedDescription)"))
        }
        completion?(.Success(finalPath))
    }
    
    func convertAndCompressVideo(asset : AVAsset, completion: ((Result<URL>) -> Void)?){
        if let asset = asset as? AVURLAsset {
            let fileSize = getFileSize(url: asset.url)
            print("Before compression \(fileSize)")
            let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mov")
            print(compressedURL)
            self.compressVideo(inputURL: asset.url , outputURL: compressedURL) { (exportSession) in
                guard let session = exportSession else {
                    self.clearTempFolder()
                    completion?(.Error("Error in Export Session while compressing the Video"))
                    return
                }
                switch session.status {
                case .unknown:
                    print("unknown")
                    break
                case .waiting:
                    print("waiting")
                    break
                case .exporting:
                    print("exporting")
                    break
                case .completed:
                    let fileSize = self.getFileSize(url: asset.url)
                    print("Before compression \(fileSize)")
                    completion?(.Success(compressedURL))
                case .failed:
                    self.clearTempFolder()
                    completion?(.Error("Export Session status failed while compressing the Video"))
                    return
                case .cancelled:
                    self.clearTempFolder()
                    completion?(.Error("Export Session status canceled while compressing the Video"))
                    return
                @unknown default:
                    self.clearTempFolder()
                    completion?(.Error("Export Session status failed while compressing the Video"))
                }
            }
        }else{
            self.clearTempFolder()
            completion?(.Error("Invalid Asses for compressing the Video"))
            return
        }
    }
    
    func covertToFileString(with size: UInt64) -> String {
        var convertedValue: Double = Double(size)
        var multiplyFactor = 0
        let tokens = ["bytes", "KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
    }

    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
            handler(nil)
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mov
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }

    fileprivate func clearTempFolder() {
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

    fileprivate func createIfNotExist(directory:Directories) {
        
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        var finalPath = url?.appendingPathComponent(directory.rawValue)
        
        do {
            if !fileManager.fileExists(atPath: (finalPath?.path)!) {
                let documentsPath1 = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                let logsPath = documentsPath1.appendingPathComponent(directory.rawValue)
                print(logsPath!)
                do {
                    try fileManager.createDirectory(atPath: logsPath!.path, withIntermediateDirectories: true, attributes: nil)
                    
                    finalPath = logsPath
                    
                } catch let error as NSError {
                    print("Unable to create directory \(error.debugDescription)")
                }
            }
        }
    }
    
    func getArrayOfImages(gifData:Data)-> [UIImage]{
        var images = [UIImage]()
        if let source =  CGImageSourceCreateWithData(gifData as CFData, nil){
            let imageCount = CGImageSourceGetCount(source)
            for i in 0 ..< imageCount {
                if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    images.append(UIImage(cgImage: image))
                }
            }
        }else{
            images.append(UIImage.sd_animatedGIF(with: gifData))
        }
        return images
    }
    
    func fetchActualAVAsset(asset:AVAsset, completion: @escaping (AVAsset?,URL?,Bool) -> Void) {
        if asset.isKind(of: AVComposition.self){
            DispatchQueue.main.async {
                HUD.show(.systemActivity)
            }
            let avCompositionAsset = asset as! AVComposition
            let exporter = AVAssetExportSession(asset: avCompositionAsset, presetName: AVAssetExportPresetPassthrough)
            clearTempFolder()
            let tempUrl = URL(fileURLWithPath: "\(NSTemporaryDirectory())TrimmedMovie.mov")
            exporter!.outputURL = tempUrl
            exporter!.outputFileType = AVFileType.mov
            exporter!.shouldOptimizeForNetworkUse = true
            exporter!.exportAsynchronously {
                guard let videoURL = exporter?.outputURL, exporter?.status == .completed else {
                    completion(nil, nil,true)
                    return
                }
                completion(exporter?.asset,videoURL,true)
            }
        }else{
            completion(asset,nil,false)
        }
    }
    
    func getFileSize(url:URL)->String{
        let filePath = url.path
        var fileSize : UInt64
        do {
            //return [FileAttributeKey : Any]
            let attr = try FileManager.default.attributesOfItem(atPath: filePath)
            fileSize = attr[FileAttributeKey.size] as! UInt64
            
            //if you convert to NSDictionary, you can get file size old way as well.
            let dict = attr as NSDictionary
            fileSize = dict.fileSize()
            return "File size : \(Units(bytes: Double(fileSize)).getReadableUnit())"
        } catch {
            return "Error: \(error)"
        }
    }

    //MARK:- Watermark related methods

    func watermark(video asset:AVAsset, startTime:CMTime, duration:CMTime, watermarkText text : String!, watermarkImage image: UIImage!, watermarkPosition position : QUWatermarkPosition, completion: ((Result<URL>) -> Void)?) {
        
        DispatchQueue.global(qos: .default).async {
            
            guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
                completion?(.Error("Could not find audio track in the video"))
                return
            }
            
            let assetComposition = AVMutableComposition()
            let trackTimeRange = CMTimeRangeMake(start: startTime, duration: duration)
            
            guard let videoCompositionTrack = assetComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                completion?(.Error("Could not add audio track to the new composition track"))
                return
            }
            
            do{
                try videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: CMTime.zero)
                
                if let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first {
                    let audioCompositionTrack = assetComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                    try audioCompositionTrack?.insertTimeRange(trackTimeRange, of: audioTrack, at: CMTime.zero)
                }
                
                //0. Creating layer for watermark
                var renderSize = videoTrack.naturalSize
                if self.isVideoPortrait(asset: asset) {
                    renderSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
                }

                let parentLayer = CALayer()
                let videoLayer = CALayer()
                parentLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
                videoLayer.frame = parentLayer.frame
                parentLayer.addSublayer(videoLayer)
                
                if text != nil {
                    let titleLayer = CATextLayer()
                    titleLayer.backgroundColor = UIColor.red.cgColor
                    titleLayer.string = text
                    titleLayer.font = "Helvetica" as CFTypeRef
                    titleLayer.fontSize = 15
                    titleLayer.alignmentMode = CATextLayerAlignmentMode.center
                    titleLayer.bounds = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
                    parentLayer.addSublayer(titleLayer)
                } else if image != nil {
                    let imageLayer = CALayer()
                    
                    var xPosition : CGFloat = 0.0
                    var yPosition : CGFloat = 0.0
                    let padding : CGFloat = 10.0
                    
                    let scaledImage = image.resizedImageWithinRect(rectSize: renderSize)
                    imageLayer.contents = scaledImage.cgImage
                    let size = scaledImage.size.applying(CGAffineTransform(scaleX: 0.2, y: 0.2))

                    switch (position) {
                    case .BottomLeft:
                        xPosition = padding
                        yPosition = padding
                        break
                    case .BottomRight:
                        xPosition = (renderSize.width - size.width) - padding
                        yPosition = padding
                        break
                    case .TopLeft:
                        xPosition = padding
                        yPosition = (renderSize.height - size.height) - padding
                        break
                    case .TopRight, .Default:
                        xPosition = (renderSize.width - size.width) - padding
                        yPosition = (renderSize.height - size.height) - padding
                        break
                    }
                    
                    imageLayer.frame = CGRect(x: xPosition, y: yPosition, width: size.width, height: size.height)
                    imageLayer.opacity = 0.65
                    parentLayer.addSublayer(imageLayer)
                }
                
                //1. Create the instructions
                let mainInstructions = AVMutableVideoCompositionInstruction()
                mainInstructions.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
                
                //2 add the layer instructions
                let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
                layerInstructions.setTransform(videoTrack.preferredTransform, at: CMTime.zero)
                layerInstructions.setOpacity(1.0, at: CMTime.zero)
                mainInstructions.layerInstructions = [layerInstructions]
                
                //3 Create the main composition and add the instructions
                
                let videoComposition = AVMutableVideoComposition()
                videoComposition.renderSize = renderSize
                videoComposition.instructions = [mainInstructions]
                videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
                videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
                
                let tempUrl = URL(fileURLWithPath: "\(NSTemporaryDirectory())TrimmedMovie.mov")
                try? FileManager.default.removeItem(at: tempUrl)
                
                let exportSession = AVAssetExportSession(asset: assetComposition, presetName: AVAssetExportPresetHighestQuality)
                exportSession?.outputFileType = AVFileType.mov
                exportSession?.shouldOptimizeForNetworkUse = true
                exportSession?.videoComposition = videoComposition
                exportSession?.outputURL = tempUrl
                exportSession?.exportAsynchronously(completionHandler: {
                    
                    DispatchQueue.main.async {
                        guard let videoURL = exportSession?.outputURL, exportSession?.status == .completed else {
                            completion?(.Error((exportSession?.error?.localizedDescription)!))
                            return
                        }
                        self.createIfNotExist(directory: .Video)
                        guard let finalPath = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(Directories.Video.rawValue + "/\(Directories.prefixForDirectory(.Video))" + String(Date().timeIntervalSince1970) + "." + tempUrl.pathExtension) else {
                            completion?(.Error("Could not generate final path to save audio."))
                            return
                        }
                        
                        do {
                            if !self.fileManager.fileExists(atPath: (finalPath.path)) {
                                try self.fileManager.copyItem(at:videoURL, to: finalPath)
                                self.clearTempFolder()
                                completion?(.Success(finalPath))
                            }
                        } catch {
                            completion?(.Error(error.localizedDescription))
                        }
                    }
                })
            }catch{
                completion?(.Error(error.localizedDescription))
            }
        }
    }
    
    //MARK:- Filter Video related methods

    func filterVideo(_ asset:AVAsset, startTime:CMTime, duration:CMTime, videoComposition: AVVideoComposition? , completion: ((Result<URL>) -> Void)?) {
        let tempUrl = URL(fileURLWithPath: "\(NSTemporaryDirectory())TrimmedMovie.mov")
        try? FileManager.default.removeItem(at: tempUrl)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = AVFileType.mov
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.videoComposition = videoComposition
        exportSession?.outputURL = tempUrl
        exportSession?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                guard let videoURL = exportSession?.outputURL, exportSession?.status == .completed else {
                    completion?(.Error((exportSession?.error?.localizedDescription)!))
                    return
                }
                self.createIfNotExist(directory: .Video)
                guard let finalPath = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(Directories.Video.rawValue + "/\(Directories.prefixForDirectory(.Video))" + String(Date().timeIntervalSince1970) + "." + tempUrl.pathExtension) else {
                    completion?(.Error("Could not generate final path to save audio."))
                    return
                }
                do {
                    if !self.fileManager.fileExists(atPath: (finalPath.path)) {
                        try self.fileManager.copyItem(at:videoURL, to: finalPath)
                        self.clearTempFolder()
                        completion?(.Success(finalPath))
                    }
                } catch {
                    completion?(.Error(error.localizedDescription))
                }
            }
        })
    }
    
    func getThumbnailImage(asset: AVAsset) -> UIImage? {
        var image = UIImage()
        do {
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 60), actualTime: nil)
            image = UIImage(cgImage: cgImage, scale:1.0, orientation: self.videoToUIImageOrientation(asset: asset))
        }
        catch let error {
            print(error.localizedDescription)
        }
        return image
    }
    
    func videoToUIImageOrientation(asset: AVAsset) -> UIImage.Orientation{
        let clipVideoTrack:AVAssetTrack = asset.tracks( withMediaType: AVMediaType.video ).first!
        let videoTransform:CGAffineTransform = clipVideoTrack.preferredTransform
        let videoUIInterfaceOrientation: UIInterfaceOrientation = getVideoOrientation(transform: videoTransform, track: clipVideoTrack)
        switch videoUIInterfaceOrientation {
        case .landscapeLeft:
            return UIImage.Orientation.down
        case .landscapeRight:
            return UIImage.Orientation.up
        case .portrait :
            return UIImage.Orientation.right
        case .portraitUpsideDown :
            return UIImage.Orientation.left
        default:
            return UIImage.Orientation.right
        }
    }
    
    func getVideoOrientation(transform:CGAffineTransform, track: AVAssetTrack) -> UIInterfaceOrientation {
        switch (transform.tx, transform.ty) {
        case (0, 0):
            return .landscapeRight
        case (track.naturalSize.width, track.naturalSize.height):
            return .landscapeLeft
        case (0, track.naturalSize.width):
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    func createFilteredImage(filterName: String, image: UIImage) -> UIImage {
        
//        if(image == nil){
////          image = UIImage.init(named: "Appicon"))!
//            image = #imageLiteral(resourceName: "video")
//        }
        
        // 1 - create source image
        let bundle = Bundle(for: type(of:self))
        let sourceImage = CIImage(image: image) ?? UIImage(named: "video", in: bundle, compatibleWith: nil)!
        
        // 2 - create filter using name
        let filter = CIFilter(name: filterName)
        filter?.setDefaults()
        
        // 3 - set source image
        filter?.setValue(sourceImage, forKey: kCIInputImageKey)
        
        // 4 - output filtered image as cgImage with dimension.
        let context = CIContext(options: nil)
        let outputCGImage = context.createCGImage((filter?.outputImage!)!, from: (filter?.outputImage!.extent)!)
        
        // 5 - convert filtered CGImage to UIImage
        let filteredImage = UIImage(cgImage: outputCGImage!, scale: image.scale, orientation: image.imageOrientation)
        
        return filteredImage
    }
    
    //MARK:- Reverse Video related methods
    
    func reverseVideo(_ videoAsset: AVAsset, completion: @escaping ((Result<URL>)) -> Void) {
        
        let media_queue = DispatchQueue(label: "mediaInputQueue", attributes: [])
        
        var completeMoviePath: URL?
        var videoSize = CGSize.zero

        // An interger property to store the maximum samples in a pass (100 is the optimal number)
        let numberOfSamplesInPass = 100

        // Initialize the reader

        self.createIfNotExist(directory: .Video)
        completeMoviePath = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(Directories.Video.rawValue + "/\(Directories.prefixForDirectory(.Video))" + String(Date().timeIntervalSince1970) + "." + "mov")

        media_queue.async {
            if let completeMoviePath = completeMoviePath {
                let videoTrack = videoAsset.tracks(withMediaType: .video).first
                
                if let firstAssetTrack = videoTrack {
                    videoSize = firstAssetTrack.naturalSize
                }
                
                /// create setting for the pixel buffer
                
                let sourceBufferAttributes: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
                var writer: AVAssetWriter!
                
                do {
                    let reader = try AVAssetReader(asset: videoAsset)
                    
                    if let assetVideoTrack = videoAsset.tracks(withMediaType: .video).first {
                        let videoCompositionProps = [AVVideoAverageBitRateKey: assetVideoTrack.estimatedDataRate]
                        
                        /// create the basic video settings
                        let videoSettings: [String : Any] = [
                            AVVideoCodecKey  : AVVideoCodecType.h264,
                            AVVideoWidthKey  : videoSize.width,
                            AVVideoHeightKey : videoSize.height,
                            AVVideoCompressionPropertiesKey: videoCompositionProps
                        ]
                        
                        let readerOutput = AVAssetReaderTrackOutput(track: assetVideoTrack, outputSettings: sourceBufferAttributes)
                        readerOutput.supportsRandomAccess = true
                        
                        assert(reader.canAdd(readerOutput))
                        reader.add(readerOutput)
                        
                        if reader.startReading() {
                            var timesSamples = [CMTime]()
                            
                            while let sample = readerOutput.copyNextSampleBuffer() {
                                let presentationTime = CMSampleBufferGetPresentationTimeStamp(sample)
                                
                                timesSamples.append(presentationTime)
                            }
                            
                            if timesSamples.count > 1 {
                                let totalPasses = Int(ceil(Double(timesSamples.count) / Double(numberOfSamplesInPass)))
                                
                                var passDictionaries = [[String: Any]]()
                                var passStartTime = timesSamples.first!
                                var passTimeEnd = timesSamples.first!
                                let initEventTime = passStartTime
                                var initNewPass = false
                                
                                for (index, time) in timesSamples.enumerated() {
                                    passTimeEnd = time
                                    
                                    if index % numberOfSamplesInPass == 0 {
                                        if index > 0 {
                                            let dictionary = [
                                                "passStartTime": passStartTime,
                                                "passEndTime": passTimeEnd
                                            ]
                                            
                                            passDictionaries.append(dictionary)
                                        }
                                        
                                        initNewPass = true
                                    }
                                    
                                    if initNewPass {
                                        passStartTime = passTimeEnd
                                        initNewPass = false
                                    }
                                }
                                
                                if passDictionaries.count < totalPasses || timesSamples.count % numberOfSamplesInPass == 0 {
                                    let dictionary = [
                                        "passStartTime": passStartTime,
                                        "passEndTime": passTimeEnd
                                    ]
                                    
                                    passDictionaries.append(dictionary)
                                }
                                
                                writer = try AVAssetWriter(outputURL: completeMoviePath, fileType: .m4v)
                                let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                                writerInput.expectsMediaDataInRealTime = false
                                writerInput.transform = videoTrack?.preferredTransform ?? CGAffineTransform.identity
                                
                                let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
                                
                                assert(writer.canAdd(writerInput))
                                
                                writer.add(writerInput)
                                
                                if writer.startWriting() {
                                    
                                    writer.startSession(atSourceTime: initEventTime)
                                    
                                    assert(pixelBufferAdaptor.pixelBufferPool != nil)
                                    
                                    var frameCount = 0
                                    
                                    for dictionary in passDictionaries.reversed() {
                                        if let passStartTime = dictionary["passStartTime"] as? CMTime, let passEndTime = dictionary["passEndTime"] as? CMTime {
                                            let passDuration = CMTimeSubtract(passEndTime, passStartTime)
                                            let timeRange = CMTimeRangeMake(start: passStartTime, duration: passDuration)
                                            
                                            while readerOutput.copyNextSampleBuffer() != nil { }
                                            
                                            readerOutput.reset(forReadingTimeRanges: [NSValue(timeRange: timeRange)])
                                            
                                            var samples = [CMSampleBuffer]()
                                            
                                            while let sample = readerOutput.copyNextSampleBuffer() {
                                                samples.append(sample)
                                            }
                                            
                                            for (index, _) in samples.enumerated() {
                                                let presentationTime = timesSamples[frameCount]
                                                let imageBufferRef = CMSampleBufferGetImageBuffer(samples[samples.count - index - 1])!
                                                
                                                while (!writerInput.isReadyForMoreMediaData) {
                                                    Thread.sleep(forTimeInterval: 0.05)
                                                }
                                                
                                                pixelBufferAdaptor.append(imageBufferRef, withPresentationTime: presentationTime)
                                                
                                                frameCount += 1
                                            }
                                            
                                            samples.removeAll()
                                        }
                                    }
                                    
                                    writerInput.markAsFinished()
                                    
                                    DispatchQueue.main.async {
                                        writer.finishWriting(completionHandler: {
                                            completion(.Success(completeMoviePath))
                                        })
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    completion(.Error("Couldn't read the supplied video's frames."))
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(.Error("Failed to start reading video frames"))
                            }
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.Error(error.localizedDescription))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(.Error("Can't find the Documents directory"))
                }
            }
        }
    }
    
    //Merge Video Related Method
    
    func videoCompositionInstruction(_ track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform)
        
        var scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.width
        if assetInfo.isPortrait {
            scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor), at: CMTime.zero)
        } else {
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            var concat = assetTrack.preferredTransform.concatenating(scaleFactor)
                .concatenating(CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.width / 2))
            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                let windowBounds = UIScreen.main.bounds
                let yFix = assetTrack.naturalSize.height + windowBounds.height
                let centerFix = CGAffineTransform(translationX: assetTrack.naturalSize.width, y: yFix)
                concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
            }
            instruction.setTransform(concat, at: CMTime.zero)
        }
        
        return instruction
    }
    
    func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    //MARK:- Merge Video Related Method
    
    func mergeVideoComposition(arrayVideos:[AVAsset], videoQuality:VideoQuality, completion: @escaping ((Result<URL>)) -> Void){

        var insertTime = CMTime.zero
        var arrayLayerInstructions:[AVMutableVideoCompositionLayerInstruction] = []
        var outputSize = CGSize.init(width: 0, height: 0)
        var isFirstIndex:Bool = false
        
        // Determine video output size
        for videoAsset in arrayVideos {
            let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video)[0]
            
            var videoSize = videoTrack.naturalSize
            if isVideoPortrait(asset: videoAsset) == true {
                videoSize.width = videoTrack.naturalSize.height
                videoSize.height = videoTrack.naturalSize.width
            }
            if !isFirstIndex{
                outputSize = videoSize
                isFirstIndex = true
            }
        }
        
        // Silence sound (in case of video has no sound track)
        let bundle = Bundle(for: type(of:self))
        let silenceURL = bundle.url(forResource: "silence", withExtension: "mp3")
        let silenceAsset = AVAsset(url:silenceURL!)
        let silenceSoundTrack = silenceAsset.tracks(withMediaType: AVMediaType.audio).first
        
        // Init composition
        let mixComposition = AVMutableComposition.init()
        
        for videoAsset in arrayVideos {
            // Get video track
            guard let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first else { continue }
            
            // Get audio track
            var audioTrack:AVAssetTrack?
            if videoAsset.tracks(withMediaType: AVMediaType.audio).count > 0 {
                audioTrack = videoAsset.tracks(withMediaType: AVMediaType.audio).first
            }
            else {
                audioTrack = silenceSoundTrack
            }
            
            // Init video & audio composition track
            let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                let startTime = CMTime.zero
                let duration = videoAsset.duration
                
                // Add video track to video composition at specific time
                try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                           of: videoTrack,
                                                           at: insertTime)
                
                // Add audio track to audio composition at specific time
                if let audioTrack = audioTrack {
                    try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                               of: audioTrack,
                                                               at: insertTime)
                }
                
                // Add instruction for video track
                
                let layerInstruction = videoCompositionInstructionForTrack(track: videoCompositionTrack!,
                                                                           asset: videoAsset,
                                                                           standardSize: outputSize,
                                                                           atTime: insertTime)
                
                // Hide video track before changing to new track
                let endTime = CMTimeAdd(insertTime, duration)
                
                layerInstruction.setOpacity(0, at: endTime)

                
                arrayLayerInstructions.append(layerInstruction)
                
                // Increase the insert time
                insertTime = CMTimeAdd(insertTime, duration)
            }
            catch {
                print("Load track error")
            }
        }
        
        // Main video composition instruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: insertTime)
        mainInstruction.layerInstructions = arrayLayerInstructions

        // Main video composition
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = outputSize

        let tempUrl = URL(fileURLWithPath: "\(NSTemporaryDirectory())TrimmedMovie.mov")
        try? FileManager.default.removeItem(at: tempUrl)
        
        let exportSession = AVAssetExportSession(asset: mixComposition, presetName: videoQuality.rawValue)
        exportSession?.outputFileType = AVFileType.mov
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.videoComposition = mainComposition
        exportSession?.outputURL = tempUrl
        exportSession?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                guard let videoURL = exportSession?.outputURL, exportSession?.status == .completed else {
                    completion(.Error((exportSession?.error?.localizedDescription)!))
                    return
                }
                
                self.createIfNotExist(directory: .Video)
                guard let finalPath = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(Directories.Video.rawValue + "/\(Directories.prefixForDirectory(.Video))" + String(Date().timeIntervalSince1970) + "." + tempUrl.pathExtension) else {
                    completion(.Error("Could not generate final path to save audio."))
                    return
                }
                
                do {
                    if !self.fileManager.fileExists(atPath: (finalPath.path)) {
                        try self.fileManager.copyItem(at:videoURL, to: finalPath)
                        self.clearTempFolder()
                        completion(.Success(finalPath))
                    }
                } catch {
                    completion(.Error(error.localizedDescription))
                }
            }
        })
    }
    
    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset, standardSize:CGSize, atTime: CMTime) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform: transform)
        
        var widthRatio:CGFloat = 1
        var heightRatio:CGFloat = 1
        
        var aspectFillRatio:CGFloat = 1
        if assetTrack.naturalSize.height < assetTrack.naturalSize.width {
            widthRatio = standardSize.width / assetTrack.naturalSize.width
            heightRatio = standardSize.height / assetTrack.naturalSize.width
        }
        else {
            widthRatio = standardSize.width / assetTrack.naturalSize.height
            heightRatio = standardSize.height / assetTrack.naturalSize.height
        }
        
        if assetInfo.isPortrait {
            aspectFillRatio = heightRatio
        }else{
            aspectFillRatio = widthRatio
        }

        if assetInfo.isPortrait {
            let scaleFactor = CGAffineTransform(scaleX: aspectFillRatio, y: aspectFillRatio)
            
            let posX = standardSize.width/2 - (assetTrack.naturalSize.height * aspectFillRatio)/2
            let posY = standardSize.height/2 - (assetTrack.naturalSize.width * aspectFillRatio)/2
            let moveFactor = CGAffineTransform(translationX: posX, y: posY)
            
            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(moveFactor), at: atTime)
            
        } else {
            let scaleFactor = CGAffineTransform(scaleX: aspectFillRatio, y: aspectFillRatio)
            
            let posX = standardSize.width/2 - (assetTrack.naturalSize.width * aspectFillRatio)/2
            let posY = standardSize.height/2 - (assetTrack.naturalSize.height * aspectFillRatio)/2
            let moveFactor = CGAffineTransform(translationX: posX, y: posY)
            
            var concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(moveFactor)
            
            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                concat = fixUpsideDown.concatenating(scaleFactor).concatenating(moveFactor)
            }
            
            instruction.setTransform(concat, at: atTime)
        }
        return instruction
    }
}

extension UIImage {
    
    /// Returns a image that fills in newSize
    func resizedImage(newSize: CGSize) -> UIImage {
        // Guard newSize is different
        guard self.size != newSize else { return self }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    /// Returns a resized image that fits in rectSize, keeping it's aspect ratio
    /// Note that the new image size is not rectSize, but within it.
    func resizedImageWithinRect(rectSize: CGSize) -> UIImage {
        let widthFactor = size.width / rectSize.width
        let heightFactor = size.height / rectSize.height
        
        var resizeFactor = widthFactor
        if size.height > size.width {
            resizeFactor = heightFactor
        }
        let newSize = CGSize(width: size.width/resizeFactor, height: size.height/resizeFactor)
        let resized = resizedImage(newSize: newSize)
        return resized
    }
}

