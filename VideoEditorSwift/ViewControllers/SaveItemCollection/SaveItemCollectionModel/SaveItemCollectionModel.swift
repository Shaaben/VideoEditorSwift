//
//  SaveItemCollectionModel.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import Foundation

class SaveItemCollectionModel: NSObject{
    var url: URL?
    var isSelected: Bool
    
    override init(){
        isSelected = false
        url = URL.init(string: "")
    }
}
