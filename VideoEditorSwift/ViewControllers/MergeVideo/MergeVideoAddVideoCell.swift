//
//  MergeVideoAddVideoCell.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//
import UIKit

protocol MergeVideoAddVideoCellDelegate: class {
    func addVideo()
}

class MergeVideoAddVideoCell: UICollectionViewCell {
    weak var delegate: MergeVideoAddVideoCellDelegate?
    
    @IBAction func onPressAddVideo(_ sender: UIButton) {
        delegate?.addVideo()
    }
}
