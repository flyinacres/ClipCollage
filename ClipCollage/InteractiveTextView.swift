//
//  InteractiveTextView.swift
//  JSONTechTest
//
//  Created by Ronald Fischer on 11/17/15.
//  Copyright © 2015 qpiapps. All rights reserved.
//

import UIKit

class InteractiveTextView: InteractiveView, UITextViewDelegate {
    
    var textView: UITextView
    var superView: UIView
    
    // Need to have a margin so that taps outside the text area will result in actions
    let itvMargin: CGFloat = 16.0
    
    init(str: String, sv: UIView) {
        superView = UIView()
        textView = UITextView()
        
        superView.addSubview(textView)
        
        super.init(tv: superView, sv: sv)
        
        textView.clipsToBounds = true
        textView.layer.cornerRadius = 10
        superView.clipsToBounds = true
        superView.layer.cornerRadius = 10
        
        textView.text = str
        textView.font = UIFont(name: textView.font!.fontName, size: 32)
        
        textView.sizeToFit()
        
        superView.backgroundColor = UIColor.lightGrayColor()
        textView.backgroundColor = UIColor.clearColor()
        textView.becomeFirstResponder()
        
        // A key setting to prevent text from jumping around as it is added
        textView.scrollEnabled = false
        
        // Adjust the size of the text and superview, just as it is done
        // when the text changes
        textViewDidChange(textView)
        
        // Adjust the text coloring, just as should occur when editing begins
        textViewDidBeginEditing(textView)
        
        // Start the text in the horizontal center, but above the midline
        superView.center = CGPoint(x: compositionView.center.x, y: compositionView.center.y - 100)
        
        textView.userInteractionEnabled = true
        textView.delegate = self
    }

    // Make a copy of this interactive text view
    override func clone() {
        let theStr = textView.text
        let itv = InteractiveTextView(str:  theStr, sv: compositionView)
        let t = getViewProperties()
        let newPoint = CGPoint(x: t.theCenter.x + 10, y: t.theCenter.y + 10)
        itv.setViewProperties(newPoint, theTransform: t.theTransform, theZPosition: t.theZPosition + 1)
    }
    
    // The text should start editing--do the proper set up
    func textViewDidBeginEditing(theTextView: UITextView) {
        
        // Only one text box should be editing at a time--clear out any others
        for iv in interactiveViews {
            if iv is InteractiveTextView {
                let itv = iv as! InteractiveTextView
                if itv != self {
                    itv.endEditing()
                }
            }
        }
        
        // Give the superview a color so it can be more easily manipulated
        superView.backgroundColor = UIColor.blackColor()
        theTextView.backgroundColor = UIColor.lightGrayColor()
    }
    
    // Clean up as editing ends
    func endEditing() {
        superView.backgroundColor = UIColor.clearColor()
        textView.backgroundColor = UIColor.clearColor()
        textView.endEditing(true)
    }
    
    // The text is changing so resize the views as appropriate
    // This looks simple but was damn hard to figure out.
    func textViewDidChange(theTextView: UITextView) {

        // Determine the new text size
        let newSize = theTextView.sizeThatFits(CGSize(width: CGFloat.max, height: CGFloat.max))
        textView.sizeToFit()
        
        // resize the frame, which should always have the same margin, even
        // though the width and height may change
        theTextView.frame = CGRectMake(-(itvMargin / 2), -(itvMargin / 2), newSize.width, newSize.height)
        
        superView.bounds = CGRectMake(theTextView.bounds.origin.x - itvMargin, theTextView.bounds.origin.y - itvMargin, theTextView.bounds.width + itvMargin, theTextView.bounds.height + itvMargin)

    }
    
    // Override so that the text 'handles' can be shown...
    override func handlePan(recognizer:UIPanGestureRecognizer) {
        textViewDidBeginEditing(textView)
        super.handlePan(recognizer)
    }

    override func handlePinch(recognizer : UIPinchGestureRecognizer) {
        textViewDidBeginEditing(textView)
        super.handlePinch(recognizer)
    }
    
    override func handleRotate(recognizer : UIRotationGestureRecognizer) {
        textViewDidBeginEditing(textView)
        super.handleRotate(recognizer)
    }
    
    override func tappedView(recognizer : UITapGestureRecognizer){
        textViewDidBeginEditing(textView)
        super.tappedView(recognizer)
    }
    
    override func tapped2View(recognizer : UITapGestureRecognizer){
        textViewDidBeginEditing(textView)
        super.tapped2View(recognizer)
    }
    
    override func swipedView(recognizer : UISwipeGestureRecognizer){
        textViewDidBeginEditing(textView)
        super.swipedView(recognizer)
    }
    
    override func longPressedView(recognizer : UILongPressGestureRecognizer){
        textViewDidBeginEditing(textView)
        super.longPressedView(recognizer)
    }

}
