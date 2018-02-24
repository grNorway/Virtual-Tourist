//
//  CoreDataStack.swift
//  Virtual Tourist
//
//  Created by scythe on 2/17/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import Foundation
import CoreData

struct CoreDataStack {
    
    //MARK: - Properties
    
    private let model : NSManagedObjectModel
    internal let coordinator : NSPersistentStoreCoordinator
    private let modelURL: URL
    internal let dbURL : URL
    internal let persistingContext : NSManagedObjectContext
    internal let backgroundContext : NSManagedObjectContext
    let context : NSManagedObjectContext
    
    //MARK: Initializers
    
    init?(modelName: String) {
        
        //Assumes the model is in the main bundle
        
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else{
            print("Unable to find \(modelName) in the main budle")
            return nil
        }
        
        self.modelURL = modelURL
        
        //Try to create the model from the URL
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else{
            print("unable to create a model from \(modelURL)")
            return nil
        }
        
        self.model = model
        
        //create the store coordinator
        
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        //Create a persistingContext (private queue) and a child on (main queue)
        //Create a context and add connect it to the coordinator
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = coordinator
        
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = persistingContext
        
        //Create a background context child for main context
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = context
        
        //Add a SQLLite store located in the documents folder
        
        let fileManager = FileManager.default
        
        guard let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to reach the documents folder")
            return nil
        }
        
        
        self.dbURL = docURL.appendingPathComponent("model.sqlite")
        print(self.dbURL)
        let options = [NSInferMappingModelAutomaticallyOption : true , NSMigratePersistentStoresAutomaticallyOption: true]
        
        do{
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: options as [NSObject:AnyObject]?)
        }catch{
            print("Unableto add store at \(dbURL)")
        }
        
        
        
    }
    
    //MARK: Utilities
    
    func addStoreCoordinator(_ storeType: String , configuration: String? , storeURL: URL , options : [NSObject : AnyObject]?) throws {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: nil)
    }
    
}

internal extension CoreDataStack {
    
    func dropAllData() throws{
        
        try coordinator.destroyPersistentStore(at: dbURL, ofType: NSSQLiteStoreType, options: nil)
        try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
    }
}

//MARK: - Core DataStack (Save Data)

extension CoreDataStack {
    
    func save() {
        // We call this synchronously, but it's a very fast
        // operation (it doesn't hit the disk). We need to know
        // when it ends so we can call the next save (on the persisting
        // context). This last one might take some time and is done
        // in a background queue
        context.performAndWait() {
            
            if self.context.hasChanges {
                do {
                    try self.context.save()
                    print("Save Context")
                } catch {
                    fatalError("Error while saving main context: \(error.localizedDescription)")
                }
                
                // now we save in the background
                self.persistingContext.perform() {
                    do {
                        try self.persistingContext.save()
                        print("Save persistingContext")
                    } catch {
                        fatalError("Error while saving persisting context: \(error)")
                    }
                }
                
                
            }
        }
    }
    
    func autoSave(_ delayInSeconds : Int) {
        
        if delayInSeconds > 0 {
            do {
                try self.context.save()
                print("Autosaving")
            } catch {
                print("Error while autosaving \(error.localizedDescription)")
            }
            
            let delayInNanoSeconds = UInt64(delayInSeconds) * NSEC_PER_SEC
            let time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
            
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.autoSave(delayInSeconds)
            }
        }
    }
    
}

