//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by scythe on 2/17/18.
//  Copyright © 2018 scythe. All rights reserved.
//
//

import Foundation
import CoreData


public class Pin: NSManagedObject {
    
    convenience init(latitude : Double , longitude : Double , context : NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context){
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
            self.creationDate = Date()
            self.hasReturned = true
            self.numberOfImages = 0
        }else{
            fatalError("Unable To Find Entity name 'PIN'")
        }
    }
    
    var dateFormatter : String{
        get{
            let formatter = DateFormatter()
            formatter.timeStyle = .none
            formatter.dateStyle = .short
            formatter.doesRelativeDateFormatting = true
            formatter.locale = Locale.current
            return formatter.string(from: creationDate)
        }
    }

}
