//
//  LocationItemsViewController.swift
//  Virtual Tourist
//
//  Created by scythe on 2/18/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationItemsViewController: UIViewController {

    //MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var loadMorePictures: UIButton!
    
    //MARK: - Core Data Properties
    var frc : NSFetchedResultsController<NSFetchRequestResult>!
    private var insertIndexPaths: [IndexPath]!
    private var deleteIndexPaths: [IndexPath]!
    private var updateIndexPaths: [IndexPath]!
    var stack : CoreDataStack!
    
    //MARK: - Properties
    var pin : Pin!
    var numberOfItems = 0
    private var editingMode = false
    private var selectedImages = [PhotoFrame]()
    
    fileprivate let insets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    fileprivate var itemsPerRow : CGFloat = 3
    
    private enum notificationsEnabled {
        case Enabled , Disabled
    }
    
    private enum allowance {
        case Enabled , Disable
    }
    
    
    //MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        frc.delegate = self
        allowSelectionOnCells(is: .Disable)
        //checkForUnfinishedCall()
        if let pin = pin {
            executeSearch()
            setupMapView(from: pin)
        }
   
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ViewWillAppear")
        notificationsObservers(are: .Enabled)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("View Will Disappear")
        notificationsObservers(are: .Disabled)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func setupMapView(from pin:Pin){
        
        let annotation = MKPointAnnotation()
        let coordinates = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        annotation.coordinate.latitude = coordinates.latitude
        annotation.coordinate.longitude = coordinates.longitude
        mapView.addAnnotation(annotation)
        mapView.isUserInteractionEnabled = false
        mapView.setCenter(coordinates, animated: false)
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(coordinates, span)
        mapView.setRegion(region, animated: false)
    }
    
    
    //setup collectionView for cells Selection
    private func allowSelectionOnCells(is allowance:allowance){
        switch allowance{
        case .Enabled:
            collectionView.allowsMultipleSelection = true
            collectionView.allowsSelection = true
        case .Disable:
            collectionView.allowsMultipleSelection = false
            collectionView.allowsSelection = false
            
        }
    }
    
    // sets up the loadMorePhotosButton isEnable
    private func loadMorePhotos(is allowance: allowance){
        DispatchQueue.main.async {
            switch allowance{
            case .Enabled :
                self.loadMorePictures.isEnabled = true
            case .Disable:
                self.loadMorePictures.isEnabled = false
            }
        }
        
    }
    
    // Add / Remove Observers on Notifications
    private func notificationsObservers(are observers: notificationsEnabled){
        switch observers{
        case .Enabled:
            NotificationCenter.default.addObserver(self, selector: #selector(pinNumberOfImagesChanged), name: .pinNumberOfImages, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(loadAlertMsg(_:)), name: .errorMessageToAlertController, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(enableCellsSelection), name: .allowCellSelection, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(enableLoadMorePicturesButton), name: .enableLoadMorePictures, object: nil)
        case .Disabled:
            NotificationCenter.default.removeObserver(self, name: .pinNumberOfImages, object: nil)
            NotificationCenter.default.removeObserver(self, name: .errorMessageToAlertController, object: nil)
            NotificationCenter.default.removeObserver(self, name: .allowCellSelection, object: nil)
            NotificationCenter.default.removeObserver(self, name: .enableLoadMorePictures, object: nil)
        }
    }
    
    deinit {
        frc.delegate = nil
        print("LocationItemsViewController deinit")
    }
    
    @objc private func pinNumberOfImagesChanged(){
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }

    // triggers a alertController to show a alert message
    @objc private func loadAlertMsg(_ notification: Notification){
        
        if let errorString = notification.userInfo?["errorString"] as? String{
            if errorString == "" {
                return
            }
            let alert = UIAlertController(title: "Error", message: errorString, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    //Enables the collectionView to allow Selection / Multiple selection
    @objc func enableCellsSelection(){
        DispatchQueue.main.async {
            self.allowSelectionOnCells(is: .Enabled)
        }
        
    }
    
    //Enables The LoadMoreButton
    @objc  func enableLoadMorePicturesButton(){
//        DispatchQueue.main.async {
//            self.loadMorePhotos(is: .Enabled)
//        }
        self.loadMorePhotos(is: .Enabled)
    }
    
    // Updates the pin.numberOfImages
    private func getNumberOfItems(from results: Int){
        
        if pin.hasReturned && pin.numberOfImages > Int(pin.images!.count){
            if editingMode{
                pin.numberOfImages = Int16(collectionView.visibleCells.count) //Int16(pin.images!.count - results)
                
            }else{
                pin.numberOfImages = 0
            }
        }else{
            pin.numberOfImages -= Int16(results)
        }
        
        
    }
    
    //Unselect Selected Cells
    private func unselectCollectionViewCells(for indexPath:IndexPath){
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell{
            if cell.deleteLabel.isHidden == false{
                cell.deleteLabel.isHidden = true
            }
        }
    }
    
    
    //Delete Selected Cells
    private func deleteSelectedObjects(){
        
        var results = [PhotoFrame]()
        do{
            results = try stack.context.fetch(frc.fetchRequest) as! [PhotoFrame]
        }catch{
            print("Error Fetch obj for Deletion")
        }
        
        for result in results{
            for selectedImage in selectedImages{
                if result == selectedImage {
                        self.stack.context.performAndWait {
                            self.stack.context.delete(result)
                        }
                        print("Deleted Object")
                    
                }else{
                    print("Not egual")
                }
            }
        }
        
        
        
        getNumberOfItems(from: selectedImages.count)
        selectedImages.removeAll()
        
        stack.save()
        let a = try? stack.context.count(for: frc.fetchRequest)
        print("a: \(a)")
        editingMode = false
        loadMorePictures.setTitle("Load More Pictures", for: .normal)
        allowSelectionOnCells(is: .Enabled)
        print("NumberOfImages : \(pin.numberOfImages) , pin.images.count : \(pin.images?.count) , pin.images?.allObjects.count : \(pin.images?.allObjects.count)")
    
    }
    
    // deletes all images for Pin
    private func deleteAllPhotoFrameObjForPin() -> Int {
        
        let results = frc.fetchedObjects!
        stack.context.performAndWait {
            for photoFrame in frc.fetchedObjects!{
                    self.stack.context.delete(photoFrame as! NSManagedObject)
            }
        }
        
        print(results.count)
        print("P I N Deleted: \(pin)")
        return  results.count
    }
    
    
    private func checkForUnfinishedCall(){
        if !pin.hasReturned && pin.images?.count == Int(pin.numberOfImages){
            allowSelectionOnCells(is: .Enabled)
            loadMorePhotos(is: .Enabled)
            stack.context.perform {
                print("Pin Updated hasReturned")
                self.pin.hasReturned = true
            }
           
            
        }
    }
    
    
    //LoadMorePictures button
    // 1) deletes selected pictures
    // 2) triggers get method
    @IBAction func loadMorePicturesAction(_ sender: UIButton) {
        
        //Cancel Allowance for selection
        if editingMode{
            deleteSelectedObjects()
        }else{
            //Call FlickrClient Get Method
            //mapView.isFirstResponder
            mapView.setNeedsDisplay()
            let numberOfDeletedPhotos = deleteAllPhotoFrameObjForPin()
            getNumberOfItems(from: numberOfDeletedPhotos)
            //pin.numberOfImages = 0
            //collectionView.reloadData()
            loadMorePhotos(is: .Disable)
            pin.hasReturned = false
            allowSelectionOnCells(is: .Disable)
            executeSearch()
            let unfinishedPin : [String:Pin] = ["unfinishedPin":pin]
            FlickrClient.sharedInstance.getPhotosFromFlickr(pin: pin, completionHandlerForGetPhotosFromFlickrDownloadedItems: { (success, numberOfWillDownloadItems, errorString) in
                NotificationCenter.default.post(name: .addUnfinishedPinToAppDelegate, object: nil, userInfo: unfinishedPin)
                if success {
                    print("success number of items \(numberOfWillDownloadItems) Pin:\(self.pin.numberOfImages)")
                    NotificationCenter.default.post(name: .pinNumberOfImages, object: nil)
                    
                }else{
                    print("Not Success Get number of items \(numberOfWillDownloadItems) Pin:\(self.pin.numberOfImages)")
                    let errorString :[String: String] = ["errorString":errorString!]
                    NotificationCenter.default.post(name: .errorMessageToAlertController, object: nil, userInfo: errorString)
                }
                
            }, completionHandlerForGetPhotosFromFlickrFinishDownloading: { (success, errorString) in
                
                if success{
                    NotificationCenter.default.post(name: .removeUnfinishedPinFromAppDelegate, object: nil, userInfo: unfinishedPin)
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Pin")
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

                    var results1 = [Pin]()

                    do{
                        results1 = try self.stack.context.fetch(fetchRequest) as! [Pin]
                    }catch{
                        print("Error Load More Save")
                    }

                    for result in results1{
                        if result == self.pin{
                            self.stack.context.performAndWait {
                                self.pin.hasReturned = true
                                self.stack.save()
                            }
                        }
                    }

                    print(" P I N Success : \(self.pin)")
                    print(" **** Finished downloading photos backgroundContext")
                    NotificationCenter.default.post(name: .allowCellSelection, object: nil)
                    NotificationCenter.default.post(name: .enableLoadMorePictures, object: nil)
                }else{
                    print(" **** Not success downloading photos backgroundContext")
                    if errorString == ""{
                    }else{
                        let errorString :[String:String] = ["errorString":errorString!]
                        NotificationCenter.default.post(name: .errorMessageToAlertController, object: nil, userInfo: errorString)
                    }
                }
            })
        }
        
    }
    

}


            // -------- EXTENSIONS -------- //
//MARK: CollectionView - Delegate
extension LocationItemsViewController : UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        editingMode = true
        loadMorePictures.setTitle("Delete Selected Items", for: .normal)
        
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell{
            cell.deleteLabel.isHidden = false
        }
        
        let selectedPhotoFrame = frc.object(at: indexPath) as! PhotoFrame
        self.selectedImages.append(selectedPhotoFrame)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if editingMode{
            let selectedItem = frc.object(at: indexPath) as! PhotoFrame
            if let index = selectedImages.index(of: selectedItem){
                selectedImages.remove(at: index)
            }
            
            if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell{
                cell.deleteLabel.isHidden = true
            }
            
            guard selectedImages.count != 0 else{
                editingMode = false
                loadMorePictures.setTitle("Load More Pictures", for: .normal)
                return
            }
            
        }
    }
    
}

//MARK: CollectionView - Data Source
extension LocationItemsViewController : UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if pin.hasReturned && pin.numberOfImages > pin.images!.count {
            
            loadMorePhotos(is: .Enabled)
            allowSelectionOnCells(is: .Enabled)
            pin.numberOfImages = Int16(pin.images!.count)
            print("1 NumberOfImages : \(pin.numberOfImages) | pin.images.count : \(pin.images?.count)")
            return pin.images!.count
            
//        }else if pin.hasReturned && pin.numberOfImages == pin.images!.count{
//
//            loadMorePhotos(is: .Enabled)
//            allowSelectionOnCells(is: .Enabled)
//            print("2 NumberOfImages : \(pin.numberOfImages) | pin.images.count : \(pin.images?.count)")
//            //pin.numberOfImages = Int16(collectionView.visibleCells.count)
//            return Int(pin.numberOfImages)
            
        
        }else{
            print("3")
            return Int(pin.numberOfImages)
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! CollectionViewCell
        cell.configureCell(cell: cell, indexPath: indexPath, frc: frc)
        return cell
    }
}

extension LocationItemsViewController : UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = insets.left * (itemsPerRow + 1)
        let availableWidth = self.view.bounds.width - paddingSpace
        let itemWidth = availableWidth / itemsPerRow
        
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return insets.left * (itemsPerRow - 2)
    }
}

extension LocationItemsViewController : MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = "location"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            pinView.animatesDrop = true
            pinView.isEnabled = true
            pinView.canShowCallout = false
            
            annotationView = pinView
        }
        
        return annotationView
        
        
    }
}

extension LocationItemsViewController : NSFetchedResultsControllerDelegate{
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertIndexPaths = [IndexPath]()
        deleteIndexPaths = [IndexPath]()
        updateIndexPaths = [IndexPath]()
        if pin.hasReturned{
            pin.hasReturned = false
        }
        
        print("*** controller will change content")
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type{
            
        case .insert:
            print("Insert an Item at \(newIndexPath!)")
            self.insertIndexPaths.append(newIndexPath!)
            
        case .delete:
            print("Delete an Item")
            deleteIndexPaths.append(indexPath!)
            
        case .update:
            print("Update an item")
            updateIndexPaths.append(indexPath!)
            
        case .move:
            print("move")
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        self.collectionView.performBatchUpdates({
            
            for indexPath in self.insertIndexPaths {
                print("Insert at \(indexPath)")
                self.collectionView.reloadItems(at: [indexPath])
                
            }
            
            for indexPath in self.deleteIndexPaths {
                print("Delete")
                print("Pin.NumberOfImages : \(pin!.numberOfImages)")
                
                unselectCollectionViewCells(for: indexPath)
                self.collectionView.deleteItems(at: [indexPath])
                
                //Fix error MSG
//                if pin.numberOfImages == 0 {
//                    self.errorMessage.text = "No Available Photos"
//                }
                
            }
            
            for indexPath in self.updateIndexPaths{
                //collectionView.reloadData()
                print("update")
                self.collectionView.reloadItems(at: [indexPath])
            }
        }, completion: {(_) in
            self.checkForUnfinishedCall()
        })
        
        
        
    }
    
}

extension LocationItemsViewController {
    
    func executeSearch() {
        if let fc = frc {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(String(describing: frc))")
            }
        }
    }
}


