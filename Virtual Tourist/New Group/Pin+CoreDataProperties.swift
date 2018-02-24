//
//  Pin+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by scythe on 2/17/18.
//  Copyright © 2018 scythe. All rights reserved.
//
//

import Foundation
import CoreData


extension Pin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin")
    }

    @NSManaged public var creationDate: Date
    @NSManaged public var hasReturned: Bool
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var numberOfImages: Int16
    @NSManaged public var images: NSSet?

}

// MARK: Generated accessors for images
extension Pin {

    @objc(addImagesObject:)
    @NSManaged public func addToImages(_ value: PhotoFrame)

    @objc(removeImagesObject:)
    @NSManaged public func removeFromImages(_ value: PhotoFrame)

    @objc(addImages:)
    @NSManaged public func addToImages(_ values: NSSet)

    @objc(removeImages:)
    @NSManaged public func removeFromImages(_ values: NSSet)

}
