//
//  MainViewController.swift
//  JSONTechTest
//
//  Created by Ronald Fischer on 11/15/15.
//  Copyright © 2015 qpiapps. All rights reserved.
//

import UIKit

var curBackgroundImage: UIImage? = nil



class MainViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var compositionView: UIView!
    
    @IBOutlet weak var mainImage: UIImageView!
    

    @IBAction func clearAll(sender: UIButton) {
        curBackgroundImage = nil
        mainImage = nil
        interactiveViews.removeAll()
        for subview in compositionView.subviews {
            subview.removeFromSuperview()
        }
    }
    
    @IBAction func addTextView(sender: AnyObject) {
        _ = InteractiveTextView(str: "Grabbable Text", sv: compositionView)

        // Need to set the delegate here, as we want clicks in this view to disable editing
//        let itv = iv.interactiveView as! UITextView
//        itv.delegate = self
    }


    // Create and save the image in the composition view when requested
    @IBAction func saveImage(sender: AnyObject) {
        let savedmage = saveEntireView(compositionView)
        
        UIImageWriteToSavedPhotosAlbum(savedmage, self,
            "imageResult:didFinishSavingWithError:contextInfo:", nil)
    }

    // Error that can result from attempting to save the image
    func imageResult(image: UIImage, didFinishSavingWithError
        error: NSErrorPointer, contextInfo:UnsafePointer<Void>) {
            
            if error != nil {
                // Report error to user
                print("Error! \(error)")
            }
    }
    
    // Select the image which will be the base of the composition
    @IBAction func selectBaseImage(sender: AnyObject) {
        let image = UIImagePickerController()
        image.delegate   = self
        // change the .PHotoLibrary to .Camera to select that
        image.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        image.allowsEditing = false
        
        self.presentViewController(image, animated: true, completion: nil)
    }
    

    // Callback to pick image and get metadata.  Although, apparently metadata is only available
    // with camera images, not saved images.
    // TODO: See if there is a way for me to add metadata to images
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
//        let metadata = info[UIImagePickerControllerMediaMetadata] as? NSDictionary
          let image = info[UIImagePickerControllerOriginalImage] as? UIImage
//        let url = info[UIImagePickerControllerReferenceURL] as? NSURL
//        let mediaType = info[UIImagePickerControllerMediaType] as? NSString
        
        // Make sure the image is properly oriented
        if let newImage = image {
            if (newImage.size.height > newImage.size.width) {
                curBackgroundImage = newImage
            } else {
                curBackgroundImage = UIImage(CGImage: (newImage.CGImage)!,
                    scale: 1.0,
                    orientation: UIImageOrientation.Left)
            }
        }
        
        mainImage.image = curBackgroundImage

    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func saveEntireView(saveView: UIView) -> UIImage {
        UIGraphicsBeginImageContext(saveView.bounds.size);
        saveView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return outputImage
    }
    

    // If the user taps outside of the text, stop editing it
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for iv in interactiveViews {
            if iv is InteractiveTextView {
                let itv = iv as! InteractiveTextView
                itv.endEditing()
            }
        }
    }

    
    // Only support portrait mode for now
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        let orientation: UIInterfaceOrientationMask = [UIInterfaceOrientationMask.Portrait, UIInterfaceOrientationMask.PortraitUpsideDown]
        return orientation
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let backgroundImage = curBackgroundImage {
            mainImage.image = backgroundImage
        }
        compositionView.clipsToBounds = true
        
        // Readd any pre-existing artwork
        for iv in interactiveViews {
            iv.reAdd(compositionView)
        }
        
        // Now add the selected artwork, then remove all from the selected
        // set.  If this duplicates pre-existing artwork that is fine--if it
        // was selected again, assume it was for a good reason.
        for art in selectedArt {
            // This is automatically added to the interactiveViews array
            _ = InteractiveImageView(artInfo: art, sv: compositionView)
        }
        selectedArt.removeAll()
    }
    

    

}
