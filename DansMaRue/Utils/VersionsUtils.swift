 //
//  VersionsUtils.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 03/05/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import Foundation
import SwiftyJSON

public class VersionsUtils: UIViewController {
    typealias VersionUtilsResponse = (Bool, NSError?) -> Void
    
    func isLatestVersion( onCompletion: @escaping VersionUtilsResponse ) {
        let currentVersion: String = Bundle.main.version
        var storeVersion=""
        
        getVersionFromStore(onCompletion: { version, err in
            storeVersion = String(describing: version.rawValue)
            onCompletion(self.compareVersion(currentVersion: currentVersion, storeVersion: storeVersion), nil)            
        })
    }
    
    private func getVersionFromStore( onCompletion: @escaping ServiceResponse ) {
        let identifier = Bundle.main.bundleIdentifier!
        let url = "https://itunes.apple.com/lookup?bundleId=\(identifier)"
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: OperationQueue.main)
        
        if Reach().connectionStatus() {
            let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                if let jsonData = data {
                    let json:JSON = JSON(jsonData)
                    if let jsonDictionary = json.dictionary{
                        if let answer = jsonDictionary["results"]?.array![0].dictionary {
                            onCompletion(answer["version"]!, nil)
                        }
                    }
                } else {
                    print(error!)
                }
            })
            task.resume()
        } 
    }
    
    //true si storeVersion est plus récente
    private func compareVersion(currentVersion: String, storeVersion: String)-> Bool {
        return currentVersion.versionToInt().lexicographicallyPrecedes(storeVersion.versionToInt())
    }    
}

