//
//  VideoFilterModel.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import UIKit

class VideoFilterModel: NSObject {
    var isSelected: Bool
    var filterName: String
    var filterDisplayName: String
    init(dict :[String:AnyHashable]){
        self.isSelected = dict["isSelected"] as! Bool
        self.filterName = dict["FilterName"] as! String
        self.filterDisplayName = dict["FilterDisplayName"] as! String
    }
}
