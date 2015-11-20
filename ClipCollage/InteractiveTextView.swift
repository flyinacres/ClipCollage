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
    let itvMargin: CGFloat = 10.0
    
    init(str: String, sv: UIView) {
        superView = UIView()
        textView = UITextView()
        
        superView.addSubview(textView)


        
        super.init(tv: superView, sv: sv)
        
        textView.clipsToBounds = true
        textView.layer.cornerRadius = 10
        
        textView.text = str
        textView.font = UIFont(name: textView.font!.fontName, size: 32)
        
        textView.sizeToFit()
        
        
        superView.backgroundColor = UIColor.lightGrayColor()
        textView.backgroundColor = UIColor.clearColor()
        textView.becomeFirstResponder()
        textView.scrollEnabled = false
        
        superView.bounds = CGRectMake(textView.bounds.origin.x - itvMargin, textView.bounds.origin.y - itvMargin, textView.bounds.width + itvMargin, textView.bounds.height + itvMargin)
        
        // Start the text in the horizontal center, but above the midline
        superView.center = CGPoint(x: compositionView.center.x, y: compositionView.center.y - 100)

        
//        textView.translatesAutoresizingMaskIntoConstraints = false
//        superView.translatesAutoresizingMaskIntoConstraints = false
//        
//        print("text view center: \(textView.center)")
//        let xCenterConstraint = NSLayoutConstraint(item: textView, attribute: .CenterX, relatedBy: .Equal, toItem: superView, attribute: .CenterX, multiplier: 1, constant: 0)
//        superView.addConstraint(xCenterConstraint)
//        
//        let yCenterConstraint = NSLayoutConstraint(item: textView, attribute: .CenterY, relatedBy: .Equal, toItem: superView, attribute: .CenterY, multiplier: 1, constant: 0)
//        superView.addConstraint(yCenterConstraint)
//        print("text view center after constraints: \(textView.center)")
//        print("text view frame after constraints: \(textView.frame)")
        
        textView.userInteractionEnabled = true
        textView.delegate = self
    }
    
    func endEditing() {
        superView.backgroundColor = UIColor.clearColor()
        textView.endEditing(true)
    }
    
    override func clone() {
        let theStr = textView.text
        let itv = InteractiveTextView(str:  theStr, sv: compositionView)
        let t = getViewProperties()
        let newPoint = CGPoint(x: t.theCenter.x + 10, y: t.theCenter.y + 10)
        itv.setViewProperties(newPoint, theTransform: t.theTransform, theZPosition: t.theZPosition + 1)
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        // Give the superview a color so it can be more easily manipulated
        superView.backgroundColor = UIColor.lightGrayColor()
    }
    
    func textViewDidChange(textView: UITextView) {

        // Determine the new text size
        let newSize = textView.sizeThatFits(CGSize(width: CGFloat.max, height: CGFloat.max))
        textView.sizeToFit()
        
        // resize the bounds
        textView.frame = CGRectMake(textView.frame.origin.x, textView.frame.origin.y, newSize.width, newSize.height)
        
        superView.bounds = CGRectMake(textView.bounds.origin.x - itvMargin, textView.bounds.origin.y - itvMargin, textView.bounds.width + itvMargin, textView.bounds.height + itvMargin)

    }



}
