//
//  Constants.swift
//  Virtual Tourist
//
//  Created by scythe on 2/19/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import Foundation

struct Constants {
    
    //MARK: Flickr
    
    struct Flickr {
        
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
    }
    
    struct FlickrParameterKeys {
        
        static let Method = "method"
        static let ApiKey = "api_key"
        static let BBox = "bbox"
        static let SafeSearch = "safe_search"
        static let latitude = "lat"
        static let longitude = "lon"
        static let PerPage = "per_page"
        static let page = "page"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJsonCallBack = "nojsoncallback"
        
        
    }
    
    struct FlickrParameterValues{
        
        static let SearchMethod = "flickr.photos.search"
        static let ApiKeyValue = "84edcced8181ebedb7b98c3547bc86f7"
        static let SafeSearchValue = "1"
        static let ExtrasURL_NValue = "url_n"
        static let ExtrasURL_MValue = "url_m"
        static let PerPageValue = "21"
        static var pageValue = ""
        static let FormatValue = "json"
        static let NoJsonCallBackValue = "1"
    }
    
    struct FlickrResponseKeys {
        
        static let Photos = "photos"
        static let Photo = "photo"
        static let URL_N = "url_n"
        static let URL_M = "url_m"
    }
    
}

