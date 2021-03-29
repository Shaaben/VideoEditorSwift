//
//  GalleryItemCell.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import UIKit

class GalleryItemCell: UITableViewCell {

    @IBOutlet weak var imgItem: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblCreatedDate: UILabel!

    var dateFormatter = DateFormatter()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureWithItem(_ objAudio:SaveItemCollectionModel){
        if let url = objAudio.url{
            let bundle = Bundle(for: type(of:self))
            imgItem.image = UIImage(named: "audio", in: bundle, compatibleWith: nil)!
            lblName.text = url.lastPathComponent
            lblCreatedDate.text = ""
            if let timeStamp = url.lastPathComponent.components(separatedBy: ".").first?.components(separatedBy: "_")[1]{
                lblCreatedDate.text = "Created at: \(self.dateFormatter.string(from: Date(timeIntervalSince1970: Double(timeStamp)!)))"
            }
        }
    }
    
    func configureWithItem(_ url:URL, currentFeature:SaveAppFeatures)
    {
        let bundle = Bundle(for: type(of:self))
        switch currentFeature
        {
        case .GIF:
            imgItem.image = UIImage(named: "gif", in: bundle, compatibleWith: nil)!
            break
        case .Images:
            imgItem.image = UIImage(named: "Image", in: bundle, compatibleWith: nil)!
            break
        case .Video:
            imgItem.image = UIImage(named: "video", in: bundle, compatibleWith: nil)!
            break
        default:
            imgItem.image = UIImage(named: "Image", in: bundle, compatibleWith: nil)!
            break
        }
        
        lblName.text = url.lastPathComponent
        lblCreatedDate.text = ""
        if let timeStamp = url.lastPathComponent.components(separatedBy: ".").first?.components(separatedBy: "_")[1]{
            lblCreatedDate.text = "Created at \(self.dateFormatter.string(from: Date(timeIntervalSince1970: Double(timeStamp)!)))"
        }
    }
}
