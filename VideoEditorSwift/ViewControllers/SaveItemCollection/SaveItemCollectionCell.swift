//
//  SaveItemCollectionCell.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import UIKit

protocol SaveItemCellDelegate : class {
    func shareData(activityController: UIActivityViewController)
    func clickedShareButtonAtIndexPath(indexPath: IndexPath)
    func clickedPlayPauseButtonAtIndexPath(indexPath: IndexPath)
}
class SaveItemCollectionCell: UICollectionViewCell {
    
    weak var delegate: SaveItemCellDelegate?
    @IBOutlet weak var imgForSaveItemPicture: UIImageView!
    @IBOutlet weak var btnForShareSaveItem: UIButton!
    @IBOutlet weak var btnForAudioStartStop: UIButton!
    var clickedIndexPath: IndexPath?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    @IBAction func btnForPlayAudio(_ sender: UIButton) {
        delegate?.clickedPlayPauseButtonAtIndexPath(indexPath: clickedIndexPath!)
    }
    @IBAction func btnShareForData(_ sender: UIButton) {
        delegate?.clickedShareButtonAtIndexPath(indexPath: clickedIndexPath!)
    }
}
