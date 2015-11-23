//
//  ManageArtwork.swift
//  JSONTechTest
//
//  Created by Ronald Fischer on 11/18/15.
//  Copyright © 2015 qpiapps. All rights reserved.
//

import UIKit
import CoreData


var persistentArt: [ArtInfo] = []
let preloadedArt0 = [216390, 183610, 166570, 214876, 221012, 4722, 86875, 15011, 1256, 81109, 38623]
let preloadedArt1 = [83473, 83479, 23513, 23052, 22343, 229167, 215601, 1125, 73711, 379, 75433, 168037, 84217, 9079]
let preloadedArt2 = [14729, 82327, 125887, 190666, 15814, 93445, 15815, 202801, 79867, 159709, 181716, 153979, 2707, 66439]
var currentPersistentArt = 0

class ManageArtwork {
    
    
    static func saveArtSet(artInfos: [ArtInfo]) {
        for art in artInfos {
            savePersistentArt(art)
        }
    }
    
    // Find the specified art.  Useful when trying to avoid dups!
    static func findArtById(artId: Double) -> ArtInfo? {
        for art in persistentArt {
            if art.artId == artId {
                return art
            }
        }
        
        return nil
    }
    
    static func savePersistentArt(artInfo: ArtInfo) {
        let appDel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        
        let newArtwork = NSEntityDescription.insertNewObjectForEntityForName("Artwork", inManagedObjectContext: context)
        
        newArtwork.setValue(artInfo.artId, forKey: "artId")
        newArtwork.setValue(artInfo.title, forKey: "title")
        // create NSData from UIImage
        guard let imageData = UIImagePNGRepresentation(artInfo.image) else {
            // handle failed conversion
            //print("Could not convert png to data")
            return
        }
        newArtwork.setValue(imageData, forKey: "image")
        
        do {
            try context.save()
        } catch {
            let alert = UIAlertView(title: "Could Not Save Clipart", message: "Your device may be low on memory.  Consider reinstalling this app.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    static func loadPersistentArt() -> [ArtInfo]? {
        var loadedArt: [ArtInfo] = []
        
        let appDel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        
        let request = NSFetchRequest(entityName: "Artwork")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.executeFetchRequest(request)
            
            for result in results as! [NSManagedObject] {
                let artId = result.valueForKey("artId")! as! Double
                let title = result.valueForKey("title")! as! String
                let imageData = result.valueForKey("image")! as! NSData
                let image = UIImage(data: imageData)
                let ai = ArtInfo(artId: artId, title: title, image: image!)
                // Build the list backwards so the most recent items are first
                loadedArt.insert(ai, atIndex: 0)
            }
        } catch {
            let alert = UIAlertView(title: "Could Not Load Saved Clipart", message: "Your saved clipart may have become corrupted.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
            return nil
        }
        
        return loadedArt
    }
    
}