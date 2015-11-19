//
//  ArtInfo.swift
//  JSONTechTest
//
//  Created by Ronald Fischer on 11/17/15.
//  Copyright © 2015 qpiapps. All rights reserved.
//

import UIKit

class ArtInfo: CustomStringConvertible {

    var artId: Double
    var title: String
    var image: UIImage
    var description: String {
        return "\(artId): \(title) \(image)"
    }
    
    init(artId: Double, title: String, image: UIImage) {
        self.artId = artId
        self.title = title
        self.image = image
        
    }
    
}
