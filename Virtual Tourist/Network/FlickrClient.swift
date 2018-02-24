//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by scythe on 2/19/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient {
    
    
    //MARK: - Singleton Instance
    static var sharedInstance = FlickrClient()
    
    //MARK: - Properties
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var stack : CoreDataStack!
    
    var session = URLSession.shared
    
    func taskForGetMethod(_ method: String? ,_ parameters : [String: AnyObject] , completionHandlerForGetMethod : @escaping (_ result: AnyObject? , _ error : NSError?) -> ()){
        
        let request = NSMutableURLRequest(url: FlickerURLFromParameters(parameters))
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func displayError(errorString : String){
                print(errorString)
                let userInfo = [NSLocalizedDescriptionKey : errorString]
                completionHandlerForGetMethod(nil,NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
            }
            
            guard error == nil else{
                displayError(errorString: error!.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else{
                print("taskForGetMethod Error : statusCode 2xx")
                displayError(errorString: NetworkErrors.Flickr2xxError)
                return
            }
            
            guard let data = data else{
                print("taskForGetMethod Error : Data")
                return
            }
            
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGetMethod)
            
        }
        task.resume()
        
    }
    
    
    //MARK: - Helpers
    
    private func FlickerURLFromParameters(_ parameters : [String:AnyObject],withPathExtension: String? = nil) -> URL{
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key,value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems?.append(queryItem)
        }
        
        return components.url!
        
    }
    
    private func convertDataWithCompletionHandler(_ data : Data , completionHandlerForConvertData: (_ result : AnyObject? , _ error : NSError?) ->()){
     
        var parsedResult : AnyObject! = nil
        
        do{
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        }catch{
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON Data: \(data)"]
            completionHandlerForConvertData(nil, NSError(domain: "ConvertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
        
    }
    
}
















