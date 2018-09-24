//
//  UIMapsUtils.swift
//  DansMaRue
//
//  Created by xavier.noel on 28/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import Foundation
import UIKit

import GoogleMaps
import GooglePlaces

class MapsUtils : NSObject {
    
    // MARK: - Properties
    private static var currentLocation = CLLocationCoordinate2D()
    static var addressLabel = ""
    static var boroughLabel = ""
    static var postalCode = ""
    static var locality = ""

        
    open class func filterToParis(resultsViewController: GMSAutocompleteResultsViewController) {
        
        // Set bounds to inner-west Paris.
        let neBoundsCorner = CLLocationCoordinate2D(latitude: 48.900838,
                                                    longitude: 2.392702)
        let swBoundsCorner = CLLocationCoordinate2D(latitude: 48.833312,
                                                    longitude: 2.256832)
        let bounds = GMSCoordinateBounds(coordinate: neBoundsCorner,
                                         coordinate: swBoundsCorner)
        
        resultsViewController.autocompleteBounds = bounds
        
        // Set up the autocomplete filter.
        let filter = GMSAutocompleteFilter()
        filter.type = .address
        filter.country = "FR"
        
        resultsViewController.autocompleteFilter = filter

    }
    
    
    // MARK: - Other Methods
    open class func userLocation() -> CLLocationCoordinate2D? {
        if MapsUtils.currentLocation.latitude == 0 {
            return nil
        }
        return MapsUtils.currentLocation
    }
    
    open class func set(userLocation: CLLocationCoordinate2D) {
        MapsUtils.currentLocation = userLocation
    }
    
    // Retourne le numero d'arrondissement
    open class func boroughLabel(postalCode: String) -> String {
        var boroughLabel = postalCode
        if postalCode.hasPrefix(Constants.prefix75) {
            let cp = String(postalCode.suffix(2))
            if let cpint = Int(cp) {
                boroughLabel = (cpint==1 ? "\(cpint) er" : "\(cpint) ème")
            }
        }
        
        return boroughLabel
    }
    
    
    open class func fullAddress() -> String {
        if MapsUtils.postalCode.hasPrefix(Constants.prefix75) {
            return "\(MapsUtils.addressLabel), \(MapsUtils.postalCode) PARIS"
        }
        return "\(MapsUtils.addressLabel), \(MapsUtils.postalCode) \(MapsUtils.locality)"
    }
    
    open class func fullAddress(gmsAddress: GMSAddress) -> String {
        return "\(gmsAddress.thoroughfare ?? ""), \(gmsAddress.postalCode ?? "") \(gmsAddress.locality ?? "")"
    }
    
    open class func getStreetAddress(address: String) -> String {
        
        let address = address
        let regexp = "75[0-9][0-9][0-9]"
        if let range = address.range(of:regexp, options: .regularExpression) {
            let rue = address.substring(to:range.lowerBound)
            return rue
        } else {
            print("##### Rue hors Paris")
        }
        return ""
    }
    
    
    open class func getPostalCode(address: String) -> String {
        
        let address = address
        let regexp = "75[0-9][0-9][0-9]"
        if let range = address.range(of:regexp, options: .regularExpression) {
            let cp = address.substring(with:range)
            return cp
        } else {
            print("##### Code postal hors Paris")
        }
        return ""
    }
    
    
    open class func addMarker(withName name: String, coordinate: CLLocationCoordinate2D, inMap mapView: GMSMapView) {
        // Suppression de tous les markers
        mapView.clear()
        
        let marker = GMSMarker()
        marker.position = coordinate
        marker.title = name
        marker.map = mapView
        
    }
    
    open class func getAddressFromCoordinate(lat: Double, long: Double, onCompletion: @escaping (GMSAddress) -> Void) {
        
        let geocoder = GMSGeocoder()
        
        geocoder.reverseGeocodeCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: long)) {
            (response: GMSReverseGeocodeResponse?, error: Error?) in
            if let error = error {
                print("Nothing found: \(error.localizedDescription)")
                return
            }
            if let addressFound = response {
                let address = addressFound.firstResult()
                onCompletion(address!)
            }
            
        }
    }
}





