//
//  PhotoFrame+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by scythe on 2/17/18.
//  Copyright © 2018 scythe. All rights reserved.
//
//

import Foundation
import CoreData


public class PhotoFrame: NSManagedObject {
    
    convenience init(pin : Pin , imageData : NSData , context : NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "PhotoFrame", in: context){
            self.init(entity: ent, insertInto: context)
            self.creationDate = Date()
            self.imageData = imageData
            self.pin = pin
            
        }else{
            fatalError("Unable To Find Entity name 'PhotoFrame' ")
        }
    }

}
