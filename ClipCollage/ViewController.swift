//
//  ViewController.swift
//  JSONTechTest
//
//  Created by Ronald Fischer on 11/13/15.
//  Copyright © 2015 qpiapps. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

var selectedArt: [ArtInfo] = []
var currentArtSet: JSON? = nil
var currentImageNum = 0
var totalResults = 0
var curResult = 0
var artSearchKey = "penguins"
var artPageNo = 1
var totalPages = 1
var curImage: UIImage? = nil
var curView: UIView? = nil
var curTitle = ""

class ViewController: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let reuseIdentifier = "artworkThumbnail"
    
    @IBOutlet weak var checkMark: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var artworkCollectionView: UICollectionView!
    
    
    @IBOutlet weak var artType: UITextField!
    
    @IBAction func searchArt(sender: AnyObject) {
        searchForNewArt()
    }
    
    func searchForNewArt() {
        if artType.text != nil {
            artSearchKey = artType.text!
        }
        
        curResult = 0
        artPageNo = 1
        getArt(artSearchKey, pageNo: artPageNo)
        
    }
    
    @IBAction func selectArt(sender: AnyObject) {
        selectNewArt()
    }
    
    
    let openClipArtSearchURL = "https://openclipart.org/search/json/"
    
    func getArt(searchKey: String, pageNo: Int) {
        
        // This seemed to be working at one point, now is always claiming no connection, even
        // when the app works
        //        if Reachability.isConnectedToNetwork() == true {
        //            //print("Internet connection OK")
        //        } else {
        //            //print("Internet connection FAILED")
        //            let alert = UIAlertView(title: "No Internet Connection", message: "Cannot fetch new art until you connect to the internet.", delegate: nil, cancelButtonTitle: "OK")
        //            alert.show()
        //            return
        //        }
        
        startAnimatingForWait()
        Alamofire.request(.GET, openClipArtSearchURL, parameters: ["query": searchKey, "amount": 10, "page": pageNo, "sort": "downloads"]).validate().responseJSON { response in
            switch response.result {
            case .Success:
                self.successfulArtFetch(response.result.value, errorMessage: "Typo?  Or make the search more general.", completion: nil)
            case .Failure(let error):
                self.stopAnimatingForWait()
                print(error)
            }
        }
    }
    
    func getArtByIds(artIds: [Int], completion: (() -> Void)!) {
        startAnimatingForWait()
        let idString = artIds.map({"\($0)"}).joinWithSeparator(",")
        // Fetch the art by a list of ids
        Alamofire.request(.GET, openClipArtSearchURL, parameters: ["byids": idString, "amount": 40]).validate().responseJSON { response in
            switch response.result {
            case .Success:
                self.successfulArtFetch(response.result.value, errorMessage: "Connect to Internet, restart app.", completion: nil)
                if completion != nil {
                    completion()
                }
            case .Failure(let error):
                self.stopAnimatingForWait()
                print(error)
            }
        }
    }
    
    
    func successfulArtFetch(responseResult: AnyObject?, errorMessage: String, completion: (() -> Void)!) {
        self.stopAnimatingForWait()
        
        if let value = responseResult {
            currentArtSet = JSON(value)
            totalPages = Int(currentArtSet!["info"]["pages"].double!)
            totalResults = Int(currentArtSet!["info"]["results"].double!)
            if totalPages == 0 {
                let alert = UIAlertView(title: "No Art Found", message: errorMessage, delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            } else {
                self.loadImageAlamoStyle(currentImageNum, completion: completion)
            }
        }
        
    }
    
    
    // Set up the wait animation, get it going
    func startAnimatingForWait() {
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.alpha = 1
        activityIndicator.startAnimating()
    }
    
    // Stop the wait animation, clean up
    func stopAnimatingForWait() {
        activityIndicator.stopAnimating()
        activityIndicator.alpha = 0
        view.sendSubviewToBack(activityIndicator)
    }
    
    func loadImageAlamoStyle(count: Int, completion: (() -> Void)!) {
        
        if currentArtSet != nil {
            let urlString =  currentArtSet!["payload"][count]["svg"]["png_thumb"].string!
            let urlwithPercentEscapes = urlString.stringByReplacingOccurrencesOfString(" ", withString: "%20")
            
            startAnimatingForWait()
            Alamofire.request(.GET, urlwithPercentEscapes)
                .response { request, response, data, error in
                    self.stopAnimatingForWait()
                    
                    if error != nil {
                        print(error)
                    } else {
                        self.displayNewImage(UIImage(data: data!)!,
                            title: currentArtSet!["payload"][count]["title"].string!,
                            countInfo: "\(curResult+1) of \(totalResults)")
                        self.nextButton.enabled = true
                        self.selectButton.enabled = true
                        if curResult > 0 {
                            self.backButton.enabled = true
                        }
                        
                        if completion != nil {
                            completion()
                        }
                    }
            }
            
        }
    }
    
    func displayNewImage(newImage: UIImage, title: String, countInfo: String) {
        
        // Remove the previously showing art
        if curView != nil {
            curView?.removeFromSuperview()
        }
        
        let tapRec = UITapGestureRecognizer()
        tapRec.addTarget(self, action: "tappedView:")
        
        let iv = UIImageView(image: newImage)
        iv.addGestureRecognizer(tapRec)
        iv.userInteractionEnabled = true
        iv.center = view.center
        
        view.addSubview(iv)
        
        curImage = newImage
        curTitle = title
        titleLabel.text = curTitle
        countLabel.text = countInfo
        
        curView = iv
    }
    
    // Tapping on a piece of art should add it to the selected list
    func tappedView(recognizer : UITapGestureRecognizer){
        selectNewArt()
    }
    
    func selectNewArt() {
        if let goodImage = curImage {
            // If there are results this is an image from a search, so select it and save it
            if totalResults > 0 {
                let artId =  currentArtSet!["payload"][currentImageNum]["id"].double!
                let title =  currentArtSet!["payload"][currentImageNum]["title"].string!
                let newArtInfo = ArtInfo(artId: artId, title: title, image: goodImage)
                
                self.view.bringSubviewToFront(checkMark)
                
                
                selectedArt.append(newArtInfo)
                // If this piece of art is not already permanently saved, make it so
                if persistUniqueArtwork(newArtInfo) {
                    persistentArt.insert(newArtInfo, atIndex: 0)
                    insertArtIntoCollection(newArtInfo)
                }
                
            } else {
                // If there are no results, this image is from the persistent set.
                // Just select it, but no need to save it again
                selectedArt.append(persistentArt[currentPersistentArt])
            }
            
            // Either way, show the cool animation
            showSelectionAnimation()
            
        }
    }
    
    // If the data is unique, persist it and return true
    func persistUniqueArtwork(artInfo: ArtInfo) -> Bool{
        if ManageArtwork.findArtById(artInfo.artId) == nil {
            // Always at newly selected stuff to the front of the list
            ManageArtwork.savePersistentArt(artInfo)
            return true
        }
        return false
    }
    
    func insertArtIntoCollection(artInfo: ArtInfo) {
        // Now insert the new item at the start of the collection view
        let nsis = NSIndexSet(index: 0)
        self.artworkCollectionView.insertSections(nsis)
        self.artworkCollectionView.reloadData()
    }
    
    
    func showSelectionAnimation() {
        self.view.bringSubviewToFront(checkMark)
        // Ease it in, then ease it out
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.checkMark.alpha = 1
            }, completion: { finished in
                UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                    self.checkMark.alpha = 0
                    }, completion: nil)
        })
    }
    
    
    @IBAction func getNextArt(sender: AnyObject) {
        currentImageNum++
        curResult++
        
        if curResult >= totalResults {
            curResult = 0
        }
        
        backButton.enabled = true
        if curResult < 1 {
            backButton.enabled = false
        }
        
        
        if currentImageNum >= currentArtSet!["payload"].count {
            currentImageNum = 0
            artPageNo++
            if artPageNo > totalPages {
                artPageNo = 1
            }
            // If there is only one page, no need to ever fetch more
            if totalPages > 1 {
                getArt(artSearchKey, pageNo: artPageNo)
            } else {
                // If it doesn't get loaded, gotta force the image to show up
                loadImageAlamoStyle(currentImageNum, completion: nil)
            }
        } else {
            loadImageAlamoStyle(currentImageNum, completion: nil)
        }
    }
    
    @IBAction func getPreviousArt(sender: AnyObject) {
        currentImageNum--
        if curResult > 0 {
            curResult--
        }
        
        if curResult < 1 {
            backButton.enabled = false
        }
        
        if currentImageNum < 0 {
            // Do not wrap backward.  Disable the back button when
            // at the first item, first page
            currentImageNum = 0
            artPageNo--
            if artPageNo <= 0  {
                artPageNo = 0
            } else {
                // Only get the art if we are not already at the first page
                getArt(artSearchKey, pageNo: artPageNo)
            }
        } else {
            loadImageAlamoStyle(currentImageNum, completion: nil)
        }
    }
    
    
    // Only support portrait mode for now
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        let orientation: UIInterfaceOrientationMask = [UIInterfaceOrientationMask.Portrait, UIInterfaceOrientationMask.PortraitUpsideDown]
        return orientation
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.alpha = 0
        
        backButton.enabled = false
        nextButton.enabled = false
        selectButton.enabled = false
        
        artType.delegate = self;
        artType.text = artSearchKey
        
        if let hasImage = curImage {
            displayNewImage(hasImage, title: curTitle, countInfo: "\(curResult+1) of \(totalResults)")
        }
        
        titleLabel.text = curTitle
        // It will only be > 0 if there are results to work with
        if totalResults > 0 {
            countLabel.text = "\(curResult+1) of \(totalResults)"
            
            nextButton.enabled = true
            selectButton.enabled = true
            if curResult > 0 {
                backButton.enabled = true
            }
        }
        
        artworkCollectionView.layer.borderWidth = 2
        artworkCollectionView.layer.cornerRadius = 20.0
        artworkCollectionView.reloadData()
        
        // Anything in persistentArt will be shown in the scrollable selector
        if let foundArt = ManageArtwork.loadPersistentArt() {
            persistentArt = foundArt
        }
        
        if persistentArt.count == 0 {
            getArtByIds(preloadedArt, completion: preloadArtwork)
        }
    }
    
    // This is a callback that is invoked when getArtByIds has
    // successfully fetched the info the preloadedArtwork
    func preloadArtwork() {
        
        // This will be incremented for each image, but only after they are saved
        currentImageNum = 0
        
        // This assumes one page of results
        for var i = 0; i < totalResults; i++ {
            loadImageAlamoStyle(i, completion: saveWhenImageLoaded)
            
        }
    }
    
    // This is a callback that is invoked when loadImageAlamoStyle has
    // succesfully loaded a relevant image.  Only after the image has
    // been loaded can it be saved to permanent storage
    func saveWhenImageLoaded() {
        let artId =  currentArtSet!["payload"][currentImageNum]["id"].double!
        let title =  currentArtSet!["payload"][currentImageNum]["title"].string!
        let newArtInfo = ArtInfo(artId: artId, title: title, image: curImage!)
        
        persistUniqueArtwork(newArtInfo)
        persistentArt.insert(newArtInfo, atIndex: 0)
        
        // Now that this is done, on to the next image
        currentImageNum++
        
        if currentImageNum == totalResults {
            dispatch_async(dispatch_get_main_queue(),  {
                self.artworkCollectionView.reloadData()
                currentImageNum = 0
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Ensure that the keyboard goes away on the return key, and the search commences
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.endEditing(true)
        searchForNewArt()
        return false
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        artType.endEditing(true)
    }
    
    
    // UICollectionViewDataSource Protocol:
    // Returns the number of rows in collection view
    internal func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    
    // UICollectionViewDataSource Protocol:
    // Returns the number of columns in collection view
    internal func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return persistentArt.count
    }
    
    
    // UICollectionViewDataSource Protocol:
    // Initializes the collection view cells
    internal func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ArtworkViewCell
        
        let i = indexPath.section
        cell.artworkThumb.alpha = 1.0
        cell.artworkThumb.image = persistentArt[i].image
        
        return cell
    }
    
    // Recognizes and handles when a collection view cell has been selected
    internal func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // let cell: UICollectionViewCell  = collectionView.cellForItemAtIndexPath(indexPath)! as UICollectionViewCell
        
        // reset the info from any search art, as it does not apply to saved art
        totalPages = 0
        totalResults = 0
        curResult = 0
        let i = indexPath.section
        let ai = persistentArt[i]
        currentPersistentArt = i
        displayNewImage(persistentArt[i].image, title: persistentArt[i].title, countInfo: "")
        showSelectionAnimation()
        
        nextButton.enabled = false
        selectButton.enabled = false
        backButton.enabled = false
        selectedArt.append(ai)
    }
    
}

