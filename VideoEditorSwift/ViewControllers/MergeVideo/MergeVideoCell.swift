//
//  MergeVideoCell.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import UIKit

protocol MergeVideoCellDelegate: class {
    func removeVideo(indexPath: IndexPath)
}

class MergeVideoCell: UICollectionViewCell {
    
    weak var delegate: MergeVideoCellDelegate?
    var indexPath:IndexPath!

    //MARK:- IBOutlets
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.configureImageView()
    }
    
    func configureImageView() {
        self.imageView.layer.cornerRadius = 5.0
    }
    
    @IBAction func onPressRemoveVideo(_ sender: UIButton) {
        delegate?.removeVideo(indexPath: self.indexPath)
    }
}
