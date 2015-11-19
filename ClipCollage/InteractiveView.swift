//
//  InteractiveView.swift
//  JSONTechTest
//
//  Created by Ronald Fischer on 11/17/15.
//  Copyright © 2015 qpiapps. All rights reserved.
//

import UIKit

// The global list of all the interactive views
var interactiveViews: [InteractiveView] = []

// Base class for all of the interactive objects in a composition view
// Must inherit from NSObject or an odd exception occurs when gesture
// recognizers are called
class InteractiveView: NSObject {
    
    var interactiveView: UIView
    var compositionView: UIView
    
    init(tv: UIView, sv: UIView) {
      
        interactiveView = tv
        compositionView = sv
        
        // super init is required after parameters are all initialized.
        // Swift is weird in many ways
        super.init()
        
        addGestureRecognizers()
        interactiveView.userInteractionEnabled = true
        compositionView.addSubview(interactiveView)
        interactiveViews.append(self)
    }
    
    // Some of this stuff will vary depending upon UITextView vs UIImageView
    
    // When the old compositionView goes out of view, a new one is required
    func reAdd(sv: UIView) {
        compositionView = sv
        compositionView.addSubview(interactiveView)
    }
    
    
    func remove() {
        interactiveView.removeFromSuperview()
        if let index = interactiveViews.indexOf(self) {
            interactiveViews.removeAtIndex(index)
        }
    }
    
    func save() {
        // Save the text or artwork
        // Save the link to the artwork
        // save the position, scale, rotation, z order (from the view?)
        //interactiveView.center
        //interactiveView.transform
        //interactiveView.layer.zPosition
    }
    
    // Based upon the current definitions this is a little strange:
    // The view has to be created, then the information will be loaded and added to it
    // But what type of view should be created?  Text or Image?  
    // Don't know until you try to load it!
    func load() {
        
    }
    
    // Basically a marker interface--it should be overridden
    func clone() {

    }
    
    // Note how the return from get must match the input to set
    func getViewProperties() -> (theCenter: CGPoint, theTransform: CGAffineTransform, theZPosition: CGFloat) {
        return (theCenter: interactiveView.center, theTransform: interactiveView.transform, theZPosition: interactiveView.layer.zPosition)
    }
    
    func setViewProperties(theCenter: CGPoint, theTransform: CGAffineTransform, theZPosition: CGFloat) {
        interactiveView.center = theCenter
        interactiveView.transform = theTransform
        interactiveView.layer.zPosition = theZPosition
    }
    
    // Cannot easily reuse gesture recognizers, so creating and attaching them here
    func addGestureRecognizers() {
        let pinchRec = UIPinchGestureRecognizer()
        let rotateRec = UIRotationGestureRecognizer()
        let panRec = UIPanGestureRecognizer()
        let tapRec = UITapGestureRecognizer()
        let tap2Rec = UITapGestureRecognizer()
        tap2Rec.numberOfTapsRequired = 2
        let swipeRec = UISwipeGestureRecognizer()
        let longPressRec = UILongPressGestureRecognizer()
        
        pinchRec.addTarget(self, action: "handlePinch:")
        rotateRec.addTarget(self, action: "handleRotate:")
        panRec.addTarget(self, action: "handlePan:")
        tapRec.addTarget(self, action: "tappedView:")
        tap2Rec.addTarget(self, action: "tapped2View:")
        swipeRec.addTarget(self, action: "swipedView:")
        longPressRec.addTarget(self, action: "longPressedView:")
        
        interactiveView.addGestureRecognizer(pinchRec)
        interactiveView.addGestureRecognizer(panRec)
        interactiveView.addGestureRecognizer(rotateRec)
        interactiveView.addGestureRecognizer(tapRec)
        interactiveView.addGestureRecognizer(tap2Rec)
        interactiveView.addGestureRecognizer(swipeRec)
        interactiveView.addGestureRecognizer(longPressRec)
    }
    
    
    func handlePan(recognizer:UIPanGestureRecognizer) {
        let translation = recognizer.translationInView(compositionView)
        if let view = recognizer.view {
            view.center = CGPoint(x:view.center.x + translation.x,
                y:view.center.y + translation.y)
        }
        recognizer.setTranslation(CGPointZero, inView: compositionView)
        var finalPoint = CGPoint(x:recognizer.view!.center.x ,
            y:recognizer.view!.center.y )
        // 4
        finalPoint.x = min(max(finalPoint.x, 0), compositionView.bounds.size.width)
        finalPoint.y = min(max(finalPoint.y, 0), compositionView.bounds.size.height)
        recognizer.view!.center = finalPoint
        
    }
    
    func handlePinch(recognizer : UIPinchGestureRecognizer) {
        if let view = recognizer.view {
            view.transform = CGAffineTransformScale(view.transform,
                recognizer.scale, recognizer.scale)
            recognizer.scale = 1
        }
    }
    
    func handleRotate(recognizer : UIRotationGestureRecognizer) {
        if let view = recognizer.view {
            view.transform = CGAffineTransformRotate(view.transform, recognizer.rotation)
            recognizer.rotation = 0
        }
    }
    
    func tappedView(recognizer : UITapGestureRecognizer){
        compositionView.bringSubviewToFront(recognizer.view!)
    }
    
    func tapped2View(recognizer : UITapGestureRecognizer){
        clone()
    }
    
    // TODO: Too hard to do to be useful
    func swipedView(recognizer : UISwipeGestureRecognizer){
        remove()
    }
    
    func longPressedView(recognizer : UILongPressGestureRecognizer){
        
        // Make sure that this is only fired once, so wait until end
        if recognizer.state == UIGestureRecognizerState.Ended {
            remove()
        }
    }
    
}
