//
//  InteractiveColorWheelView.swift
//  ClipCollage
//
//  Created by Ronald Fischer on 11/17/15.
//  Copyright © 2015 qpiapps. All rights reserved.
//

import UIKit

class InteractiveColorWheel: InteractiveView {
    
    init(sv: UIView) {
        let image = UIImage(named: "ColorWheel.png")
        let uiv = UIImageView(image: image!)
        super.init(tv: uiv, sv: sv)
    }
    
    override func clone() {
        let iiv = InteractiveColorWheel(compositionView)
        
        let t = getViewProperties()
        let newPoint = CGPoint(x: t.theCenter.x + 10, y: t.theCenter.y + 10)
        iiv.setViewProperties(newPoint, theTransform: t.theTransform, theZPosition: t.theZPosition + 1)
    }
    
    
}
