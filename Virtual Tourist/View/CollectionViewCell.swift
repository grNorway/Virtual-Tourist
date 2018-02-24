//
//  CollectionViewCell.swift
//  Virtual Tourist
//
//  Created by scythe on 2/19/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import UIKit
import CoreData

class CollectionViewCell: UICollectionViewCell {
    
    
 
    @IBOutlet weak var collectionImageView: UIImageView!
    @IBOutlet weak var spiner: UIActivityIndicatorView!
    @IBOutlet weak var deleteLabel: UILabel!
    
    func configureCell(cell: CollectionViewCell , indexPath : IndexPath , frc : NSFetchedResultsController<NSFetchRequestResult>){
        
        setupCollectionViewCell(imageView: collectionImageView)
        cell.spiner.startAnimating()
        if frc.fetchedObjects!.count > 0 {
            
            if cell.collectionImageView.image == UIImage(named:"placeHolder"){
                if indexPath.item < frc.fetchedObjects!.count{
                    if let photoFrame = frc.object(at: indexPath) as? PhotoFrame{
                        cell.collectionImageView.image = UIImage(data: (photoFrame.imageData! as NSData) as Data)
                        cell.spiner.stopAnimating()
                    }else{
                        print("CoreData Error image found nil")
                    }
                }else{
                    print("indexPath smaller")
                }
            }
        }
    }
    
    
    private func setupCollectionViewCell(imageView : UIImageView){
        imageView.layer.borderColor = UIColor(white: 1, alpha: 0.3).cgColor
        imageView.layer.borderWidth = 1.5
        imageView.layer.cornerRadius = 15
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: "placeHolder")
    }
    
}
