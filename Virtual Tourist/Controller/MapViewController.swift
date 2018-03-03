//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by scythe on 2/17/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class MapViewController: UIViewController {

    //MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinsLabel: UILabel!
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    
    //MARK: Properties
    
    var stack : CoreDataStack!
    private var annotations = [Pin]()
    private var editingMode = false
    
    private enum coreDataObject {
        case Pin , PhotoFrame
    }
    
    var timer : Timer? = nil
    
    //MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        longPressGesture()
        fetchPinAnnotations()
    }
    
    deinit {
        print("MapViewController Deinit")
    }

    private func getFetchRequest(for object : coreDataObject) -> NSFetchRequest<NSFetchRequestResult>{
        
        switch object{
        case .Pin:
            return  NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        case .PhotoFrame:
            return NSFetchRequest<NSFetchRequestResult>(entityName: "PhotoFrame")
        }
    }
    
    // Fetching Pin Annotations and add them on the map
    private func fetchPinAnnotations(){
        mapView.removeAnnotations(mapView.annotations)
        
        //Fetch from Core Data that are saved
        let request = getFetchRequest(for: .Pin)
        request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        do{
            annotations = try stack.context.fetch(request) as! [Pin]
        }catch{
            print("Core Data Error")
        }
        
        
        for annotation in annotations{
            let annotationLocation = MKPointAnnotation()
            annotationLocation.coordinate.latitude = annotation.latitude
            annotationLocation.coordinate.longitude = annotation.longitude
            mapView.addAnnotation(annotationLocation)
        }
    }
    
    
    // Long press gesture recognizer
    private func longPressGesture(){
        
        let longRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addPinByLongPressGesture(byReactingTo:)))
        longRecognizer.minimumPressDuration = 1.0
        self.mapView.addGestureRecognizer(longRecognizer)
    }
    
    
    // Adds a Pin Annotation on the map
    // Using longGesture
    @objc private func addPinByLongPressGesture(byReactingTo longGesture: UILongPressGestureRecognizer){
        
        switch longGesture.state{
        case .began:
            print("started")
            
            let touchLocation = longGesture.location(ofTouch: 0, in: mapView)
            let locationCoordinates = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationCoordinates
            
            let pin = Pin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: stack.context)
            stack.save()
            annotations.append(pin)
            mapView.addAnnotation(annotation)
        default:
            break
        }
        
        print(mapView.annotations.count)
        
    }

    @IBAction func EditButtonPressed(_ sender: UIBarButtonItem) {
        
        switch editingMode{
        case true:
            deletePinsLabel.isHidden = true
            mapView.bounds.origin.y = mapView.bounds.origin.y - deletePinsLabel.bounds.height
            editingMode = false
            rightBarButton.title = "Edit"
            
        case false:
            deletePinsLabel.isHidden = false
            mapView.bounds.origin.y = mapView.bounds.origin.y + deletePinsLabel.bounds.height
            editingMode = true
            rightBarButton.title = "Done"
            
        }
    }
    
    private func getPinsToBackgroundContext(fetchRequest:NSFetchRequest<NSFetchRequestResult>) -> [Pin]{
        var results = [Pin]()
        
        stack.context.performAndWait {
            do{
                results = try stack.context.fetch(fetchRequest) as! [Pin]
            }catch{
                print("Core Data Error Background Fetch")
            }
        }
       
        
        return results
        
    }

    
    //MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLocationImages"{
            let locationItemsVC = segue.destination as! LocationItemsViewController
            
            let fetchRequest = getFetchRequest(for: .Pin)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            
            let fetchedResults = getPinsToBackgroundContext(fetchRequest: fetchRequest)
            
            var pin = sender as! Pin
            
            for fetchedPin in fetchedResults{
                if pin.latitude == fetchedPin.latitude && pin.longitude == fetchedPin.longitude {
                    pin = fetchedPin
                    locationItemsVC.pin = fetchedPin
                }
            }
            let pinID = pin.objectID
            print("P I N : \(pin)")
            
            let fetchRequestVC = getFetchRequest(for: .PhotoFrame)
            fetchRequestVC.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            
            let predicate = NSPredicate(format: "pin = %@", pin)
            fetchRequestVC.predicate = predicate
            
            let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequestVC, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
            locationItemsVC.frc = fetchResultsController
            locationItemsVC.stack = stack
            
            let unfinishedPin : [String:Pin] = ["unfinishedPin":pin]
            
            if pin.images?.allObjects.count == 0 && pin.hasReturned == true {
                pin.hasReturned = false
                NotificationCenter.default.post(name: .addUnfinishedPinToAppDelegate, object: nil, userInfo: unfinishedPin)
                print("Entered")
                
                FlickrClient.sharedInstance.getPhotosFromFlickr(pin: pin, completionHandlerForGetPhotosFromFlickrDownloadedItems: { (success, numberOfWillDownloadItems, errorString) in
                    
                    if success {
                        
                        print("success number of items \(numberOfWillDownloadItems) Pin:\(pin.numberOfImages)")
                        NotificationCenter.default.post(name: .pinNumberOfImages, object: nil)
                        //TODO: Send notification to AppDelegate about unfinished Pin (try to send the ObjectID)
                        
                        
                    }else{
                        print("Not Success Get number of items \(numberOfWillDownloadItems) Pin:\(pin.numberOfImages)")
                        let errorString :[String: String] = ["errorString":errorString!]
                        NotificationCenter.default.post(name: .errorMessageToAlertController, object: nil, userInfo: errorString)
                        NotificationCenter.default.post(name: .enableLoadMorePictures, object: nil)
                        DispatchQueue.main.async {
                            self.stack.context.perform{
                                pin.hasReturned = true
                            }
                            
                            print("PIN ON NOT SUCCESS : \(pin)")
                        }
                    }
                }, completionHandlerForGetPhotosFromFlickrFinishDownloading: { (success, errorString) in
                    let fetchRequest = self.getFetchRequest(for: .Pin)
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                    let results = self.getPinsToBackgroundContext(fetchRequest: fetchRequest) // <-- mainContext
                    
                    if success{
                        //self.stack.context.object(with: pinID)
                        //TODO: Send Notification to AppDelegate to make unfinished Pins Finished
                        
                        NotificationCenter.default.post(name: .removeUnfinishedPinFromAppDelegate, object: nil, userInfo: unfinishedPin)
                        
                        for result in results {
                            if result == pin{
                                self.stack.context.performAndWait{
                                    pin.hasReturned = true
                                }
                            }
                        }
                        
 
                        print(" P I N Success : \(pin)")
                        print(" **** Finished downloading photos backgroundContext")
                        NotificationCenter.default.post(name: .allowCellSelection, object: nil)
                        NotificationCenter.default.post(name: .enableLoadMorePictures, object: nil)
                    }else{
                        print(" **** Not success downloading photos backgroundContext")
                        for result in results {
                            if result == pin{
                                self.stack.context.performAndWait{
                                    pin.hasReturned = true
                                }
                            }
                        }
                        //TODO: Send Notification to LocationItems and set
                        NotificationCenter.default.post(name: .errorFinishingTheBackgroundDownloading, object: nil)
                        print(" P I N NOT Success : \(pin)")
                        //Enable load more pictures
                        //set pin.numberOfImages = pin.images?.count
                        //Make Notification for that 
                        if errorString == ""{
                        }else{
                            let errorString :[String:String] = ["errorString":errorString!]
                            NotificationCenter.default.post(name: .errorMessageToAlertController, object: nil, userInfo: errorString)
                        }
                    }
                })
            }else{
                if pin.hasReturned{
                    print("Has returned")

                    locationItemsVC.enableLoadMorePicturesButton()
                    locationItemsVC.enableCellsSelection()
                }else{
                    
//                    if pin.images?.count != 0 && pin.images!.count < Int(pin.numberOfImages){
//                        pin.hasReturned = true
//                    }else if pin.images?.count == 0 {
//                        let pinNotReturned : Pin = pin
//                        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(updatePinHasReturnedFromTimer), userInfo: pinNotReturned, repeats: false )
//                    }
                    
                    // Gets in just with !pin.hasReturned
                    if !pin.hasReturned && pin.images?.count != 0{
                        print("1")
                        //pin.hasReturned = true
                        if pin.images!.count < pin.numberOfImages{
                            print("2")
//                            stack.context.performAndWait {
//                                pin.hasReturned = true
//                                stack.save()
//                                print("Saved")
//                            }
                            
                        }
                    }else if !pin.hasReturned && pin.images?.count == 0 {
                        let pinNotReturned : Pin = pin
                        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(updatePinHasReturnedFromTimer), userInfo: pinNotReturned, repeats: false )
                    }
                }
                
            }
            
        }
    }
    
    @objc func updatePinHasReturnedFromTimer(timer:Timer){
        if let pin = timer.userInfo as? Pin {
            pin.hasReturned = true
            pin.numberOfImages = 0
            print("Timer has started")
            
            let errorString : [String: String] = ["errorString" : "Time Out. Please try again"]
            NotificationCenter.default.post(name: .errorMessageToAlertController, object: nil, userInfo: errorString)
            NotificationCenter.default.post(name: .pinNumberOfImages, object: nil)
            NotificationCenter.default.post(name: .enableLoadMorePictures, object: nil)
            
            timer.invalidate()
        }
        
    }

}

extension MapViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = "location"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            pinView.isEnabled = true
            pinView.canShowCallout = false
            pinView.animatesDrop = false
            
            annotationView = pinView
        }
        
        return annotationView
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let annotationCoordinates = view.annotation?.coordinate {
            let index = annotations.index(where: { (annotation1) -> Bool in
                return (annotation1.latitude == annotationCoordinates.latitude && annotation1.longitude == annotationCoordinates.longitude)
            })
            
            let pin = annotations[index!]
            //let annotation = mapView.annotations[index!]
            mapView.deselectAnnotation(view.annotation, animated: true)
            
            if !editingMode {
                performSegue(withIdentifier: "showLocationImages", sender: pin)
            }else{
                print("delete")
                let fetchRequest = getFetchRequest(for: .Pin)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                
                stack.context.delete(pin)
                stack.save()
                fetchPinAnnotations()
                
            }
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        
    }
    
}
