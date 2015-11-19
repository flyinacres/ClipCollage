//
//  InteractiveImageView.swift
//  JSONTechTest
//
//  Created by Ronald Fischer on 11/17/15.
//  Copyright © 2015 qpiapps. All rights reserved.
//

import UIKit

class InteractiveImageView: InteractiveView {
    var artInfo: ArtInfo
    
    init(artInfo: ArtInfo, sv: UIView) {
        self.artInfo = artInfo
        let uiv = UIImageView(image: artInfo.image)
        
        super.init(tv: uiv, sv: sv)
    }

    override func clone() {
        let iiv = InteractiveImageView(artInfo: artInfo, sv: compositionView)
        
        let t = getViewProperties()
        let newPoint = CGPoint(x: t.theCenter.x + 10, y: t.theCenter.y + 10)
        iiv.setViewProperties(newPoint, theTransform: t.theTransform, theZPosition: t.theZPosition + 1)
    }
    
    
}
