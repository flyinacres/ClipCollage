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


// All artwork that has been selected and should be added to the current composition
var selectedArt: [ArtInfo] = []

// The JSON describing the current set of clipart returned from openclipart.com
var currentArtSet: JSON? = nil

// The current image number in the current page of results
var currentImageNum = 0

// the current image number across all results should be 0 <= X <= totalResults
var curResult = 0

// The total number of results across all pages
var totalResults = 0

// The text key used to search for new clip art sets
var artSearchKey = "penguins"

// The current page in the clip art results
var artPageNo = 1

// The total number of pages in all of the clip art results
var totalPages = 1

// The current image shown on screen
var curImage: UIImage? = nil

// The view that the current image is displayed in
var curView: UIView? = nil

// The title associated with the current image
var curTitle = ""


// Manage the view which allows users to select clip art
class ViewController: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // Identifies the prototype cell in the UICollectionView
    let reuseIdentifier = "artworkThumbnail"
    
    // The URL for searching for clip art
    let openClipArtSearchURL = "https://openclipart.org/search/json/"
    
    // The number of pieces of art info to fetch at one time
    let artInfoCount = 10
    
    
    // The check mark icon for indicating the selection of artwork
    @IBOutlet weak var checkMark: UIImageView!
    
    // The activity indicator shown when art sets or images are loaded
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // The button for moving back in an art set (also left swipe will work)
    @IBOutlet weak var backButton: UIButton!
    
    // The button for moving forward in an art set (also right swipe will work)
    @IBOutlet weak var nextButton: UIButton!
    
    // The button for selecting a piece of art (also tapping the art will work)
    @IBOutlet weak var selectButton: UIButton!
    
    // The title of the artwork
    @IBOutlet weak var titleLabel: UILabel!
    
    // The count information for the current image (x of y)
    @IBOutlet weak var countLabel: UILabel!
    
    // The collection view for any selected artwork
    @IBOutlet weak var artworkCollectionView: UICollectionView!
    
    // The search text for picking new artwork
    @IBOutlet weak var artType: UITextField!
    
    // The button indicating that new artwork should be searched for
    @IBAction func searchArt(sender: AnyObject) {
        searchForNewArt()
    }
    
    // The button indicating that the current artwork should be selected
    @IBAction func selectArt(sender: AnyObject) {
        selectNewArt()
    }
    
    // The button indicating that the next art in the set should be shown
    @IBAction func getNextArt(sender: AnyObject) {
        fetchNextArt()
    }
    
    // The button indicating that the previous art in the set should be shown
    @IBAction func getPreviousArt(sender: AnyObject) {
        fetchPreviousArt()
    }
    
    // Search for new art, assuming that there is some text in the text box
    func searchForNewArt() {
        if artType.text != nil {
            artSearchKey = artType.text!
        }
        
        curResult = 0
        artPageNo = 1
        getArtBySearchKey(artSearchKey, pageNo: artPageNo)
        
    }
    
    // Fetch art from openclipart.com by use of a search term
    func getArtBySearchKey(searchKey: String, pageNo: Int) {
        
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
        
        // Flurry update for the search info
        let artParams = ["searchKey": "\(searchKey)"];
        Flurry.logEvent("Search_Text", withParameters: artParams);
        
        startAnimatingForWait()
        Alamofire.request(.GET, openClipArtSearchURL, parameters: ["query": searchKey, "amount": artInfoCount, "page": pageNo, "sort": "downloads"]).validate().responseJSON { response in
            switch response.result {
            case .Success:
                self.successfulArtFetch(response.result.value, errorMessage: "Typo?  Or make the search more general.", completion: nil)
                
            case .Failure:
                self.stopAnimatingForWait()
                let alert = UIAlertView(title: "Error Searching for Clipart", message: "Please ensure internet access, then restart this app.", delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            }
        }
    }
    
    // Fetch art from openclipart.com by way of ids, instead of a search term
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
                
            case .Failure:
                self.stopAnimatingForWait()
                let alert = UIAlertView(title: "Could Not Fetch Initial Clipart", message: "Please ensure internet access, then restart this app.", delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            }
        }
    }
    
    // An art set was successfully fetched.  Get all of the information from the JSON
    // struct, and show the first image if there is one
    func successfulArtFetch(responseResult: AnyObject?, errorMessage: String, completion: ((count: Int, image: UIImage?) -> Void)!) {
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
    
    
    // load the image as specified by the count element in the currentArtSet
    // The optional completion function will be called after the image has been
    // loaded successfully
    func loadImageAlamoStyle(count: Int, completion: ((count: Int, image: UIImage?) -> Void)!) {
        
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
                        if completion != nil {
                            completion(count: count, image: UIImage(data: data!))
                        }

                        self.displayNewImage(UIImage(data: data!)!,
                            title: currentArtSet!["payload"][count]["title"].string!,
                            countInfo: "\(curResult+1) of \(totalResults)")
                        self.setArtButtonsProperly()
                        
                    }
            }
            
        }
    }
    
    // The buttons to select the current, or fetch previous/next art
    // must be kept in sync with the current state of the artwork set
    func setArtButtonsProperly() {
        nextButton.enabled = true
        selectButton.enabled = true
        backButton.enabled = true

        if totalResults < 1 {
            nextButton.enabled = false
            selectButton.enabled = false
        }
        
        if curResult < 1 {
            backButton.enabled = false
        }

    }
    
    // Display a newly found image.  Get rid of the previous one.   Add all gesture
    // recognizers so that the image can be selected, etc.
    func displayNewImage(newImage: UIImage, title: String, countInfo: String) {
        
        // Remove the previously showing art
        if curView != nil {
            curView?.removeFromSuperview()
        }
        
        let tapRec = UITapGestureRecognizer()
        tapRec.addTarget(self, action: "tappedView:")
        
        let swipeRecLeft = UISwipeGestureRecognizer()
        swipeRecLeft.direction = UISwipeGestureRecognizerDirection.Left
        swipeRecLeft.addTarget(self, action: "swipedView:")
        
        let swipeRecRight = UISwipeGestureRecognizer()
        swipeRecRight.direction = UISwipeGestureRecognizerDirection.Right
        swipeRecRight.addTarget(self, action: "swipedView:")
        
        let iv = UIImageView(image: newImage)
        iv.addGestureRecognizer(tapRec)
        iv.addGestureRecognizer(swipeRecLeft)
        iv.addGestureRecognizer(swipeRecRight)
        iv.userInteractionEnabled = true
        iv.center = CGPoint(x: view.center.x, y: view.center.y + 10)
        
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
    
    
    // Allow next image to be selected by swipes
    func swipedView(recognizer : UISwipeGestureRecognizer){
        
        switch recognizer.direction {
            case UISwipeGestureRecognizerDirection.Right:
                fetchPreviousArt()

            case UISwipeGestureRecognizerDirection.Left:
                fetchNextArt()

            default:
                break
        }
        
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
                
                // Update the flurry info so that I get an idea as to what users are doing
                let artParams = ["artId": "\(artId)"];
                Flurry.logEvent("Artwork_selected", withParameters: artParams);
                
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
    
    
    // Actually get the next art and adjust the various counts/pages
    func fetchNextArt() {
        // If there is no next artwork, don't try to get it
        if nextButton.enabled == false {
            return
        }
        
//        print("fetchNextArt() artPageNo: \(artPageNo), currentImageNum: \(currentImageNum), curResult: \(curResult)")

        currentImageNum++
        curResult++
        
        if curResult >= totalResults {
            curResult = 0
        }
        
        setArtButtonsProperly()
        
        if currentImageNum >= currentArtSet!["payload"].count {
            currentImageNum = 0
            artPageNo++
            if artPageNo > totalPages {
                artPageNo = 1
            }
            // If there is only one page, no need to ever fetch more
            if totalPages > 1 {
                getArtBySearchKey(artSearchKey, pageNo: artPageNo)
            } else {
                // If it doesn't get loaded, gotta force the image to show up
                loadImageAlamoStyle(currentImageNum, completion: nil)
            }
        } else {
            loadImageAlamoStyle(currentImageNum, completion: nil)
        }    }
    
    

    
    // Actually get the previous art and adjust the various counts/pages
    func fetchPreviousArt() {
        if backButton.enabled == false {
            return
        }
        
//        print("fetchPreviousArt() artPageNo: \(artPageNo), currentImageNum: \(currentImageNum), curResult: \(curResult)")
        currentImageNum--
        if curResult > 0 {
            curResult--
        }
        
        setArtButtonsProperly()
        
        if currentImageNum < 0 {
            // Do not wrap backward.  Disable the back button when
            // at the first item, first page
            currentImageNum = artInfoCount - 1
            artPageNo--
            if artPageNo <= 0  {
                artPageNo = 0
                currentImageNum = 0
            } else {
                // Only get the art if we are not already at the first page
                getArtBySearchKey(artSearchKey, pageNo: artPageNo)
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
        
        setArtButtonsProperly()
        
        artType.delegate = self;
        artType.text = artSearchKey
        
        if let hasImage = curImage {
            displayNewImage(hasImage, title: curTitle, countInfo: "\(curResult+1) of \(totalResults)")
        }
        
        titleLabel.text = curTitle
        // It will only be > 0 if there are results to work with
        if totalResults > 0 {
            countLabel.text = "\(curResult+1) of \(totalResults)"
            
            setArtButtonsProperly()
        }
        
        artworkCollectionView.layer.borderWidth = 2
        artworkCollectionView.layer.cornerRadius = 20.0
        artworkCollectionView.reloadData()
        
        // Anything in persistentArt will be shown in the scrollable selector
        if let foundArt = ManageArtwork.loadPersistentArt() {
            persistentArt = foundArt
        }
        
        if persistentArt.count == 0 {
            getArtByIds(preloadedArt0, completion: preloadArtwork)
            getArtByIds(preloadedArt1, completion: preloadArtwork)
            getArtByIds(preloadedArt2, completion: preloadArtwork)
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
    
    // a queue to save the image without freezing the App UI
    let saveQueue = dispatch_queue_create("saveQueue", DISPATCH_QUEUE_SERIAL)
    
    // This is a callback that is invoked when loadImageAlamoStyle has
    // succesfully loaded a relevant image.  Only after the image has
    // been loaded can it be saved to permanent storage
    func saveWhenImageLoaded(count: Int, image: UIImage?) {
        // dispatch with gcd.
        dispatch_async(saveQueue) {
            let artId =  currentArtSet!["payload"][count]["id"].double!
            let title =  currentArtSet!["payload"][count]["title"].string!
            let newArtInfo = ArtInfo(artId: artId, title: title, image: image!)

            
            self.persistUniqueArtwork(newArtInfo)
            persistentArt.insert(newArtInfo, atIndex: 0)
            
            // Now that this is done, on to the next image
            currentImageNum++
            
            // After the last one, update the UI
            if currentImageNum == totalResults {
                dispatch_async(dispatch_get_main_queue(),  {
                    self.artworkCollectionView.reloadData()
                    currentImageNum = 0
                })
            }
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
        
        setArtButtonsProperly()
        
        selectedArt.append(ai)
    }
    
}

