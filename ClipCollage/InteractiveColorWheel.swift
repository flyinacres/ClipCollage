//
//  InteractiveColorWheelView.swift
//  ClipCollage
//
//  Created by Ronald Fischer on 11/17/15.
//  Copyright © 2015 qpiapps. All rights reserved.
//

import UIKit

class InteractiveColorWheel: InteractiveView {
    
    var uiv: UIImageView
    
    init(sv: UIView) {
        let image = UIImage(named: "ColorWheel.png")
        uiv = UIImageView(image: image!)
        super.init(tv: uiv, sv: sv)
        uiv.bounds = CGRectMake(0, 0, 150, 150)
        uiv.center = sv.center
        
        
        // Nasty cheat to mark this type of image view as special
        // Basically, I don't want colorwheels to steal the focus
        // from other objects, I want them to colorize other objects
        uiv.tag = 1
    }
    
    override func clone() {
        let iiv = InteractiveColorWheel(sv: compositionView)
        
        let t = getViewProperties()
        let newPoint = CGPoint(x: t.theCenter.x + 10, y: t.theCenter.y + 10)
        iiv.setViewProperties(newPoint, theTransform: t.theTransform, theZPosition: t.theZPosition + 1)
    }
    
    override func tapped2View(recognizer : UITapGestureRecognizer){
        
        // WHOA--notice that instead of duplicating the color wheel, a double tap is just the same as a single tap
        super.tappedView(recognizer)
    }
    
    
    // Caution-if the base image changes these values must change
    let colorWheelSize: CGFloat = 730
    override func tappedView(recognizer : UITapGestureRecognizer){
        super.tappedView(recognizer)
        var point = recognizer.locationInView(uiv)
        // Scale the point from the current position, to the position it
        // would have in the full size image
        point.x = point.x / uiv.bounds.width * colorWheelSize
        point.y = point.y / uiv.bounds.height * colorWheelSize
        
        let selectedColor = uiv.image?.getPixelColor(point)
        
        for iv in interactiveViews {
            if iv is InteractiveTextView {
                let itv = iv as! InteractiveTextView
                if itv.isEditing {
                    itv.setColor(selectedColor!)
                }
            }
        }
    }
    
}
