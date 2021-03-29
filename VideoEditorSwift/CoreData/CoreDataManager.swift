//
//  CoreDataManager.swift
//  MoDDA
//
//  Created by Jayesh on 22/05/17.
//  Copyright © 2017 Logistic Infotech Pvt. Ltd. All rights reserved.
//

import Foundation
import CoreData

class CoreDataManager {

    static let DBName = "VideoUtilityApp"
    
    // MARK: - Core Data stack
    static let sharedInstance = CoreDataManager()
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls.last!
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: CoreDataManager.DBName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("\(CoreDataManager.DBName).sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            // Configure automatic migration.
            let options = [ NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true ]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        
        var managedObjectContext: NSManagedObjectContext?
            managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext?.parent = self.privateManagedObjectContext
        return managedObjectContext!
    }()
    
    lazy var privateManagedObjectContext: NSManagedObjectContext = {
        
        var managedObjectContext: NSManagedObjectContext?
//        if #available(iOS 10.0, *){
//            managedObjectContext = self.persistentContainer.viewContext
//        }
//        else{
            // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
            let coordinator = self.persistentStoreCoordinator
            managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext?.persistentStoreCoordinator = coordinator
            
//        }
        return managedObjectContext!
    }()
    
    // iOS-10
    @available(iOS 10.0, *)
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: CoreDataManager.DBName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        print("\(self.applicationDocumentsDirectory)")
        return container
    }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        managedObjectContext.perform {
            do{
                if self.managedObjectContext.hasChanges {
                    try self.managedObjectContext.save()
                }
            }catch{
                let saveError = error as NSError
                print("Unable to Save Changes of Managed Object Context")
                print("\(saveError), \(saveError.localizedDescription)")
            }
            
            self.privateManagedObjectContext.perform {
                do{
                    if self.privateManagedObjectContext.hasChanges{
                        try self.privateManagedObjectContext.save()
                    }
                }catch{
                    let saveError = error as NSError
                    print("Unable to Save Changes of Private Managed Object Context")
                    print("\(saveError), \(saveError.localizedDescription)")
                }
            }
        }
    }
    
    //MARK: - Delete Object
    func deleteObject(object : NSManagedObject){
        self.managedObjectContext.delete(object)
        self.saveContext()
    }
    
    func deleteEntity(name : String){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try self.managedObjectContext.execute(deleteRequest)
            self.saveContext()
        } catch {
            print (error)
        }
    }
    
    //MARK: - Creating Object
    func createObjectForEntity(entityName:String) -> AnyObject{
        if (entityName != "")
        {
            let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: self.managedObjectContext)
            
            let createdObject = NSManagedObject(entity: entityDescription!, insertInto: self.managedObjectContext)
            
            return createdObject
        }
        return (nil as AnyObject?)!
    }
    
    func createObjectForEntity(entityName:String,aContext: NSManagedObjectContext) -> [AnyObject]{
        if (entityName == "")
        {
            let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: aContext)
            
            let createdObject = NSManagedObject(entity: entityDescription!, insertInto: aContext)
            
            return createdObject as AnyObject as! [AnyObject]
        }
        return ((nil) as [AnyObject]?)!
    }
    
    //MARK: - Retrive Object
    
    func getObjectsforEntity(strEntity : String) -> AnyObject {
        return self.getObjectsforEntity(strEntity: strEntity, ShortBy: "", isAscending: false, predicate: nil, groupBy: "")
    }
    
    func getObjectsforEntity(strEntity : String, ShortBy :String , isAscending : Bool ,predicate : NSPredicate! ,groupBy : NSString, recordLimit:Int? = nil) -> AnyObject {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult> (entityName: strEntity)
        fetchRequest.returnsObjectsAsFaults = false
        if predicate != nil {
            fetchRequest.predicate = predicate
        }
        
        if (ShortBy != ""){
            let sortDescriptor1 = NSSortDescriptor(key: ShortBy, ascending: isAscending)
            fetchRequest.sortDescriptors = [sortDescriptor1]
        }
        if groupBy != "" {
            fetchRequest.propertiesToGroupBy = [groupBy]
            fetchRequest.resultType = .dictionaryResultType
        }
        
        if recordLimit != nil{
            fetchRequest.fetchLimit = recordLimit!
        }
        
        do {
            let result = try self.managedObjectContext.fetch(fetchRequest)
            
            return result as AnyObject
        } catch {
            let fetchError = error as NSError
            print(fetchError)
            return nil as [AnyObject]? as AnyObject
        }
    }
    
    func getObjectsCountForEntity(strEntity : String, ShortBy :String , isAscending : Bool ,predicate : NSPredicate! ,groupBy : NSString ,usePrivateContext:Bool = false) -> Int {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult> (entityName: strEntity)
        if predicate != nil {
            fetchRequest.predicate = predicate
        }
        if (ShortBy != ""){
            let sortDescriptor1 = NSSortDescriptor(key: ShortBy, ascending: isAscending)
            fetchRequest.sortDescriptors = [sortDescriptor1]
        }
        if groupBy != "" {
            fetchRequest.propertiesToGroupBy = [groupBy]
        }
        
        do {
            let result = try managedObjectContext.count(for: fetchRequest)
            return result
        } catch {
            let fetchError = error as NSError
            print(fetchError)
            return 0
        }
    }
    
    func getUniqueObjectsforEntity(strEntity : String, arrUniqueFields : [String], ShortBy :String , isAscending : Bool) -> AnyObject {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult> (entityName: strEntity)
        
        if (ShortBy != "" && isAscending){
            let sortDescriptor1 = NSSortDescriptor(key: ShortBy, ascending: isAscending)
            fetchRequest.sortDescriptors = [sortDescriptor1]
        }
        
        fetchRequest.propertiesToFetch = arrUniqueFields
        fetchRequest.returnsDistinctResults = true
        
        do {
            let result = try self.managedObjectContext.fetch(fetchRequest)
            
            return result as AnyObject
        } catch {
            let fetchError = error as NSError
            print(fetchError)
            return nil as [AnyObject]? as AnyObject
        }
    }
    
    func deleteObjectsFromEntity(name : String, predicate:NSPredicate!, completionHandler:@escaping (_ success:Bool) -> ()){
        
        let arrObjectsToDelete = self.getObjectsforEntity(strEntity: name, ShortBy: "", isAscending: false, predicate: predicate, groupBy: "") as! NSArray
        for dbObject in arrObjectsToDelete{
            self.managedObjectContext.delete(dbObject as! NSManagedObject)
        }
        self.saveContext()
        completionHandler(true)
    }
}
