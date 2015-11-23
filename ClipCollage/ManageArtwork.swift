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
// TODO: Start with very little art to make it stable
let preloadedArt0 = [216390, 183610, 166570]
//let preloadedArt0 = [216390, 183610, 166570, 214876, 221012, 4722, 86875, 15011, 1256, 81109, 38623]
let preloadedArt1 = [83473, 83479, 23513, 23052, 22343, 229167, 215601, 1125, 73711, 379, 75433, 168037, 84217, 9079]
let preloadedArt2 = [14729, 82327, 125887, 190666, 15814, 93445, 15815, 202801, 79867, 159709, 181716, 153979, 2707, 66439]
var currentPersistentArt = 0

class ManageArtwork {
    
    static let preloadedArt = [
        (title: "Cartoon thought bubble", artId: 82327, imageName: "thought-bubble-300px.png"),
        (title: "Bulle / bubble", artId: 125887, imageName: "bulle-300px.png"),
        (title: "Speech Bubble", artId: 81109, imageName: "speech-bubble-300px.png"),
        (title: "cartoon,speech bubble", artId: 38623, imageName: "bulle5-300px.png"),
        (title: "Right or wrong 4", artId: 15814, imageName: "Arnoud999-Right-or-wrong-4-300px.png"),
        (title: "Right or wrong 5", artId: 15815, imageName: "Arnoud999-Right-or-wrong-5-300px.png"),
        (title: "Long Arrow Right", artId: 202801, imageName: "long-arrow-right-300px.png"),
        (title: "Glossy White Arrow", artId: 168037, imageName: "glossy-white-arrow-300px.png"),
        (title: "Laptop", artId: 159709, imageName: "computer-laptop-300px.png"),
        (title: "Top hat", artId: 183610, imageName: "top-hat-300px.png"),
        (title: "Santa Claus hat", artId: 166570, imageName: "Hat-of-Santa-300px.png"),
        (title: "Jester's Hat Icon", artId: 216390, imageName: "Jester-Hat-Icon-300px.png"),
        (title: "mustache", artId: 214876, imageName: "mustache-300px.png"),
        (title: "Man's Disguise", artId: 221012, imageName: "Mans-Disguise-300px.png"),
        (title: "black mask", artId: 1256, imageName: "johnny-automatic-black-mask-300px.png"),
        (title: "Dog Tags", artId: 4722, imageName: "dniezby-Dog-Tags-300px.png"),
        (title: "Halloween Teeth2", artId: 86875, imageName: "halloween-teeth2-300px.png"),
        (title: "Dragon Vector Art 1", artId: 15011, imageName: "samuraiagency-Dragon-Vector-Art-1-300px.png"),
        (title: "Gold Frame", artId: 175581, imageName: "goldframe-300px.png"),
        (title: "Christmas Icon", artId: 94231, imageName: "xmas02-300px.png"),
        (title: "Red Devil", artId: 229167, imageName: "Red-Devil-300px.png"),
        (title: "classic car", artId: 73711, imageName: "classic-car-300px.png"),
        (title: "Stop Sign", artId: 215601, imageName: "Stop-Sign-300px.png"),
        (title: "Yield Roadsign", artId: 1125, imageName: "ryanlerch-Yield-Roadsign-300px.png"),
        (title: "Banana", artId: 84217, imageName: "Banana-300px.png"),
        (title: "Flower Stack Attack clipart 3", artId: 190666, imageName: "1391760888-300px.png"),
        (title: "Flower", artId: 66439, imageName: "pun02-300px.png"),
        (title: "Cartoon Mallard", artId: 83473, imageName: "14thWarrior-Cartoon-Mallard-300px.png"),
        (title: "Cartoon Elephant", artId: 83479, imageName: "14thWarrior-Cartoon-Elephant-300px.png"),
        (title: "Cartoon tyrannosaurus rex", artId: 23513, imageName: "StudioFibonacci-Cartoon-tyrannosaurus-rex-300px.png"),
        (title: "Cartoon bunny", artId: 23052, imageName: "StudioFibonacci-Cartoon-bunny-300px.png"),
        (title: "Happy fish", artId: 2707, imageName: "Machovka-Happy-fish-300px.png"),
        (title: "Panda Holding a Sign", artId: 153979, imageName: "1312685893-300px.png")

    ]


    static var appDel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    static var context: NSManagedObjectContext = appDel.managedObjectContext
    
    
    // Load all of the initial art into the system
    static func preloadArt() {
        for art in preloadedArt {
            let artInfo = ArtInfo(artId: Double(art.artId), title: art.title, image: UIImage(named: art.imageName)!)
            savePersistentArt(artInfo)
            persistentArt.insert(artInfo, atIndex: 0)
        }
    }
    
    
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

        let newArtwork = NSEntityDescription.insertNewObjectForEntityForName("Artwork", inManagedObjectContext: context)
        
        newArtwork.setValue(artInfo.artId, forKey: "artId")
        newArtwork.setValue(artInfo.title, forKey: "title")
        // create NSData from UIImage
        guard let imageData = UIImagePNGRepresentation(artInfo.image) else {
            // handle failed conversion
            let alert = UIAlertView(title: "Could Not Convert Clipart", message: "Your device may be low on memory.  Consider reinstalling this app.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
            return
        }
        newArtwork.setValue(imageData, forKey: "image")
        
        do {
            try context.save()
        } catch (let error){
            let alert = UIAlertView(title: "Could Not Save Clipart", message: "Your device may be low on memory.  Consider reinstalling this app.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
            print(error)
        }
        
    }
    
    static func loadPersistentArt() -> [ArtInfo]? {
        var loadedArt: [ArtInfo] = []
        
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
    
    
    // Have not fully tested this yet...
    static func deleteData() {
        let fetchRequest = NSFetchRequest(entityName: "Artwork")
        fetchRequest.includesPropertyValues = false // Only fetch the managedObjectID (not the full object structure)
        do {
            let fetchResults = try context.executeFetchRequest(fetchRequest) as? [NSManagedObject]
                
            for result in fetchResults! {
                context.deleteObject(result)
            }
        } catch (let error) {
            let alert = UIAlertView(title: "Could Not Delete Clipart1", message: "Your device may be low on memory.  Consider reinstalling this app.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
            print(error)
        }
        
        do {
            try context.save()
        } catch (let error){
            let alert = UIAlertView(title: "Could Not Delete Clipart2", message: "Your device may be low on memory.  Consider reinstalling this app.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
            print(error)
        }

    }
}