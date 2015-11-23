//
//  MainViewController.swift
//  JSONTechTest
//
//  Created by Ronald Fischer on 11/15/15.
//  Copyright © 2015 qpiapps. All rights reserved.
//

import UIKit
import AVFoundation

// The image currently used as the background, if any
var curBackgroundImage: UIImage? = nil



class MainViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var savedBackgroundImage: UIImage?
    
    let captureSession = AVCaptureSession()
    
    // If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    
    // current state of the camera rotation
    var cameraFront = true
    
    var frontCamera: AVCaptureDevice? = nil
    
    var backCamera: AVCaptureDevice? = nil
    
    var liveImage = false
    
    let  stillImageOutput = AVCaptureStillImageOutput()
    
    var avcdi: AVCaptureDeviceInput?
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    
    
    @IBOutlet weak var compositionView: UIView!
    
    @IBOutlet weak var mainImage: UIImageView!
    
    @IBOutlet weak var creationLabel: UILabel!
    
    @IBOutlet weak var cameraRotateButton: UIButton!
    
    @IBOutlet weak var selectPhotoButton: UIButton!
    
    @IBOutlet weak var shutterButton: UIButton!

    @IBAction func clearAll(sender: UIButton) {
        clearComposition()
    }
    
    // Use a photo (as opposed to a live image)
    @IBAction func usePhoto(sender: AnyObject) {
        let image = UIImagePickerController()
        image.delegate   = self
        image.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        image.allowsEditing = false
        self.presentViewController(image, animated: true, completion: nil)    }
    
    @IBAction func selectColor(sender: AnyObject) {
        _ = InteractiveColorWheel(sv: compositionView)
    }
    
    @IBAction func addTextView(sender: AnyObject) {
        _ = InteractiveTextView(str: "Say What? 🎵", sv: compositionView)
        Flurry.logEvent("Add_Text");
    }

    
    @IBAction func cameraRotate(sender: AnyObject) {
        rotateCamera()
    }
    
    @IBAction func takePicture(sender: AnyObject) {
            captureLiveImage()
    }
    
    // A button or some other event caused a rotate--make it happen
    func rotateCamera() {
        if cameraFront {
            cameraFront = false
            captureDevice = backCamera
        } else {
            cameraFront = true
            captureDevice = frontCamera
        }
        
        // If a live image capture is in session, stop it and restart it with the 
        // new camera
        if liveImage {
            captureSession.stopRunning()
            if avcdi != nil {
                captureSession.removeInput(avcdi)
            }
            // Once this thread has finished, restart the camera...
            dispatch_async(dispatch_get_main_queue()) {
                self.prepForCamera()
            }
        }
    }

    // Create and save the image in the composition view when requested
    @IBAction func saveImage(sender: AnyObject) {
        let alert = UIAlertController(title: "Save Composition", message: "Would you like to save this composition to your Photo Library?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            Flurry.logEvent("Save_Image");
            let savedmage = self.saveEntireView(self.compositionView)
            
            UIImageWriteToSavedPhotosAlbum(savedmage, self,
                "imageResult:didFinishSavingWithError:contextInfo:", nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
            // No action needed
            //print("Click of cancel button")
        }))
        self.presentViewController(alert, animated: true, completion: nil)
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
        
        // Second tap of the camera icon (while the image is live) means
        // stop the camera
        if liveImage {
            // This will clean up buttons and such
            cleanUpLiveImage()
            if savedBackgroundImage == nil {
                curBackgroundImage = nil
                mainImage.image = UIImage(named: "camera.png")
                dispatch_async(dispatch_get_main_queue()) {
    
                    self.mainImage.image = nil
                }
                
            } else {
                curBackgroundImage = savedBackgroundImage
                mainImage.image = savedBackgroundImage
                savedBackgroundImage = nil
            }
            
        } else {
            let image = UIImagePickerController()
            image.delegate   = self
            image.sourceType = UIImagePickerControllerSourceType.Camera
            image.allowsEditing = false

            prepForCamera()
        }
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
        
        Flurry.logEvent("Background_Image_Selected");
        
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
    
    // Prepare for taking a photo with the camera
    func prepForCamera() {
        if captureDevice != nil {
            toggleCameraButtons(true)
            
            // Gotta clear these so that the live image can be seen
            // Otherwise these block that picture
            savedBackgroundImage = curBackgroundImage
            curBackgroundImage = nil
            mainImage.image = nil
        
            do {
                
                liveImage = true
                if avcdi != nil {
                    captureSession.removeInput(avcdi)
                }
                
                avcdi = try AVCaptureDeviceInput(device: captureDevice)
                captureSession.addInput(avcdi)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                if previewLayer != nil {
                    previewLayer!.zPosition = -11
                    compositionView.layer.addSublayer(previewLayer!)
                    
                    previewLayer!.frame = CGRect(x: 0, y: 0, width: compositionView.layer.frame.width, height: compositionView.layer.frame.height)

                    captureSession.startRunning()
                } else {
                    print("ERROR: Could not create the preview layer for live image capture")
                    cleanUpLiveImage()
                }
            } catch {
                print("error: \(error)")
            }
        }

    }
    
    // Clean up and reset the variables associated with live image selection
    func cleanUpLiveImage() {
        if liveImage {
            if captureSession.running {
                captureSession.stopRunning()
                captureSession.removeInput(self.avcdi)
            }
            if previewLayer != nil {
                previewLayer?.removeFromSuperlayer()
            }
            liveImage = false
            
            // No need to see the rotation or shutter buttons any more
            toggleCameraButtons(false)
        }
    }
    
    
    func captureLiveImage() {
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                let dataProvider = CGDataProviderCreateWithCFData(imageData)
                let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                
                // Make sure to flip the camera properly based upon which way it
                // is facing
                var uiOrientation = UIImageOrientation.Right
                if self.captureDevice == self.frontCamera {
                    // TODO: This changed for no known reason...
                    uiOrientation = UIImageOrientation.LeftMirrored
                }
                curBackgroundImage = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: uiOrientation)
                    
                self.mainImage.image = curBackgroundImage

                self.cleanUpLiveImage()
            })
        }
        
        // This is async, so nothing to do in this thread
    }
    
    // Toggle the camera buttons enabled/disabled together
    func toggleCameraButtons(toggle: Bool) {
        var alpha: CGFloat = 0
        
        if toggle {
            alpha = 1
        }
        cameraRotateButton.alpha = alpha
        cameraRotateButton.enabled = toggle
        shutterButton.alpha = alpha
        shutterButton.enabled = toggle
        
        selectPhotoButton.alpha = 1 - alpha
        selectPhotoButton.enabled = !toggle
    }
 
    
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == .MotionShake {
            clearComposition()
        }
    }

    // Clear everything so that users can start again
    func clearComposition() {
        cleanUpLiveImage()
        
        curBackgroundImage = nil
        mainImage.image = nil
        interactiveViews.removeAll()
        for subview in compositionView.subviews {
            
            // The creation label/watermark should always be there, although it is usuaslly
            // hidden.  Likewise, the mainImage should always be present, although it may be
            // blank
            if subview != creationLabel && subview != mainImage {
                subview.removeFromSuperview()
            }
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func saveEntireView(saveView: UIView) -> UIImage {
        // If they are saving a live image, take the picture!
        if liveImage {
            captureLiveImage()
        }
        
        
        creationLabel.text = "Created with ClipCollage, by qpiapps.com"
        view.bringSubviewToFront(creationLabel)
        UIGraphicsBeginImageContext(saveView.bounds.size);
        saveView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        creationLabel.text = ""
        view.sendSubviewToBack(creationLabel)
        
        return outputImage
    }
    

    // If the user taps outside of the text, stop editing it
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            // This is a nasty little hack where I make the
            // tag of the colorwheel == 1 so that it does not
            // steal the focus...
            if touch.view!.tag != 1 {
                for iv in interactiveViews {
                    if iv is InteractiveTextView {
                        let itv = iv as! InteractiveTextView
                        itv.endEditing()
                    }
                }
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
        
        view.sendSubviewToBack(creationLabel)

        if let backgroundImage = curBackgroundImage {
            mainImage.image = backgroundImage
        }
        compositionView.clipsToBounds = true
        compositionView.layer.zPosition = 0
        
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
        
        captureSession.sessionPreset = AVCaptureSessionPresetLow
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Get the user's cameras
                if (device.position == AVCaptureDevicePosition.Back) {
                    backCamera = device as? AVCaptureDevice
                } else if (device.position == AVCaptureDevicePosition.Front) {
                    frontCamera = device as? AVCaptureDevice
                }
            }
        }
        
        // default to the back camera--this will happen based on the default state of cameraFront
        rotateCamera()
        // Hide the button until a picture starts
        toggleCameraButtons(false)
        
        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        captureSession.addOutput(stillImageOutput)
    }

}
