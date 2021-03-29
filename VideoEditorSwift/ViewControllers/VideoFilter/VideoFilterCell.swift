//
//  VideoFilterCell.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import UIKit

class VideoFilterCell: UICollectionViewCell {
    
    @IBOutlet weak var filterNameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var initialLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setUpCell(model:VideoFilterModel){
        filterNameLabel.text = model.filterDisplayName
        if let initalCharacter = model.filterDisplayName.first {
            initialLabel.text = "\(initalCharacter)"
        }
        
        if model.isSelected {
            filterNameLabel.font = UIFont.boldSystemFont(ofSize: 19.0)
            initialLabel.font = UIFont.boldSystemFont(ofSize: initialLabel.font.pointSize)
            self.imageView.layer.borderColor = UIColor.darkGray.cgColor
            self.imageView.layer.borderWidth = 2.0
        }else {
            filterNameLabel.font = UIFont.systemFont(ofSize: 17.0)
            initialLabel.font = UIFont.systemFont(ofSize: initialLabel.font.pointSize)
            self.imageView.layer.borderWidth = 0.0
        }
        self.imageView.layer.cornerRadius = 5.0
    }
}
