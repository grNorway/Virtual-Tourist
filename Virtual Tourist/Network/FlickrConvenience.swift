//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by scythe on 2/19/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import Foundation
import CoreData
import MapKit

extension FlickrClient {
    
    
    
    func getPhotosFromFlickr(pin : Pin , completionHandlerForGetPhotosFromFlickrDownloadedItems : @escaping (_ success: Bool ,_ downloadedItems : Int , _ errorString : String?) -> (), completionHandlerForGetPhotosFromFlickrFinishDownloading : @escaping (_ success : Bool , _ errorsString: String?) -> () ){
        
        stack = delegate.stack
        
        connectToFlickrApi(pin: pin) { (success, photoArray, errorString) in
            if success{
                self.getNumberOfDownloadedPhotos(pin: pin, photoArray: photoArray!, { (success, downloadedItems, photoArray, errorString) in
                    if success{
                        pin.numberOfImages = Int16(downloadedItems)
                        completionHandlerForGetPhotosFromFlickrDownloadedItems(true, downloadedItems, nil)
                        
                        self.downloadImageData(pin: pin, photoArray: photoArray!, completionHandlerForDownloadImageData: { (success, errorString) in
                            
                            if success{
                                completionHandlerForGetPhotosFromFlickrFinishDownloading(true, nil)
                            }else{
                                completionHandlerForGetPhotosFromFlickrFinishDownloading(false,errorString!)
                            }
                            
                        })
                    }else{
                        print("CompletionHandlerForFlickrDownloadedItems \(errorString!)")
                        completionHandlerForGetPhotosFromFlickrDownloadedItems(false, 0, errorString!)
                    }
                    
                })
            }else{
                completionHandlerForGetPhotosFromFlickrDownloadedItems(false, 0, errorString!)
            }
        }
    }
    
    // Connects to Flickr API and returns a arrayOf Photos
    private func connectToFlickrApi(pin:Pin , _ completionHandlerForConnectToFlickrAPI : @escaping ( _ success : Bool , _ resultsArray: [[String:AnyObject]]? , _ error : String?) -> () ){
        
        Constants.FlickrParameterValues.pageValue = "\(arc4random_uniform(40) + 1)"
        
        let parameters = [Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
                          Constants.FlickrParameterKeys.ApiKey : Constants.FlickrParameterValues.ApiKeyValue,
                          Constants.FlickrParameterKeys.SafeSearch : Constants.FlickrParameterValues.SafeSearchValue,
                          Constants.FlickrParameterKeys.latitude : pin.latitude,
                          Constants.FlickrParameterKeys.longitude : pin.longitude,
                          Constants.FlickrParameterKeys.PerPage : Constants.FlickrParameterValues.PerPageValue,
                          Constants.FlickrParameterKeys.page : Constants.FlickrParameterValues.pageValue,
                          Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.ExtrasURL_NValue,
                          Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.FormatValue,
                          Constants.FlickrParameterKeys.NoJsonCallBack : Constants.FlickrParameterValues.NoJsonCallBackValue,
                          ] as [String : AnyObject]
        
        let _ = taskForGetMethod(nil, parameters) { (result, nsError) in
            
            
            guard nsError == nil else{
                completionHandlerForConnectToFlickrAPI(false, nil, nsError!.localizedDescription)
                return
            }
            
            
            if let resultsPhotos = result![Constants.FlickrResponseKeys.Photos] as? [String: AnyObject],let resultsArray = resultsPhotos[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] {
                completionHandlerForConnectToFlickrAPI(true, resultsArray, nil)
            }else{
                completionHandlerForConnectToFlickrAPI(false, nil, NetworkErrors.FlickrResponseNoKey)
            }
        }
        
    }
    
    // gets the number of the photos that are going to be downloaded so the collectionView will be prepared to
    // have the correct numbers of cells
    private func getNumberOfDownloadedPhotos(pin : Pin , photoArray: [[String:AnyObject]],_ completionHandlerForgetNumberOfDownloadedPhotos: @escaping (_ success : Bool , _ downloadedItems : Int , _ photoArray:[[String: AnyObject]]?,_ errorString: String?) -> ()){
        
        if photoArray.isEmpty{
            print("Empty array")
            completionHandlerForgetNumberOfDownloadedPhotos(false, 0, nil, NetworkErrors.FlickrReturn0Results)
        }else{
            completionHandlerForgetNumberOfDownloadedPhotos(true, photoArray.count, photoArray, nil)
        }
    }
    
    
    //Download images on BackgroundContext
    private func downloadImageData(pin:Pin , photoArray: [[String: AnyObject]], completionHandlerForDownloadImageData : @escaping (_ finished: Bool , _ errorString: String?) -> ()){
        stack = delegate.stack
        
        for dictionary in photoArray{
            
            if let URLString = dictionary[Constants.FlickrResponseKeys.URL_N] as? String{
                if let imageURL = URL(string: URLString){
                    
                    guard let imageData = try? Data(contentsOf: imageURL) else{
                        print("Error ImageData")
                        completionHandlerForDownloadImageData(false, "It appears there is no Internet connection.Please Check you Internet Connection")
                        return
                    }
                    
                    let pinCoordinates = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                    let pinSaved = checkForDeletedPin(stack: stack, pinCoordinates: pinCoordinates)
                    
                    if !pinSaved{
                        print("Pin is Deleted")
                        completionHandlerForDownloadImageData(false,"")
                    }else{
                            self.stack.context.perform {
                                let _ = PhotoFrame(pin: pin, imageData: imageData as NSData, context: self.stack.context)
                                
//                                do{
//                                    try self.stack.context.save()
//                                    print("OK downloaded")
//                                }catch{
//                                    print("Error Saving BackgroundContext")
//                                    completionHandlerForDownloadImageData(false, NetworkErrors.FLickrInternalError)
//                                    //TODO: Core Data FatalError
//                                }
                                
                            }
                        
                    }
                }else{
                    print("Error : if let imageURL")
                    completionHandlerForDownloadImageData(false, NetworkErrors.FLickrInternalError)
                }
            }else{
                print("Error: if let URLString")
                completionHandlerForDownloadImageData(false, NetworkErrors.FLickrInternalError)
            }
        }
        
        completionHandlerForDownloadImageData(true, nil)
        
    }
    
    
}

// ----- Helper Functions ----- //

// Check for deleted pin
private func checkForDeletedPin(stack : CoreDataStack , pinCoordinates : CLLocationCoordinate2D) -> Bool {
    
    let request = NSFetchRequest<NSFetchRequestResult>(entityName:"Pin")
    request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    
    let predicateLatitude = NSPredicate(format: "latitude = %lf", pinCoordinates.latitude)
    let predicateLongitude = NSPredicate(format: "longitude = %lf", pinCoordinates.longitude)
    request.predicate = NSCompoundPredicate(type: .and, subpredicates: [predicateLatitude,predicateLongitude])
    
    var results = [Pin]()
    stack.context.performAndWait {
        do{
            results = try stack.context.fetch(request) as! [Pin]
        }catch{
            print("Error Checking Deleted Pin")
        }
    }
    
    if results.count == 0 {
        return false
    }else{
        return true
    }
}













