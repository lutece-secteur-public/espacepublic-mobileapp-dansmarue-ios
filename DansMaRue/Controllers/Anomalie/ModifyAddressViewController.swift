//
//  ModifyAddressViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 23/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps

class ModifyAddressViewController: UIViewController {

    
    //MARK: - Properties
    // Google SearchBar properties
    let addressNotification = Notification.Name(rawValue:Constants.NoticationKey.addressNotification)
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    
    // Equipements SeachBar properties
    var customSearchController: UISearchController?
    var equipementSearchController: EquipementSearchTableViewController?
    var typeEquipementSelected: TypeEquipement?

    weak var delegate : AddAnomalyViewController!

    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Initialize searchBar en fonction du context
        if delegate.typeContribution == .indoor {
            if let selectedEquipement = delegate.selectedEquipement {
                self.typeEquipementSelected = ReferalManager.shared.getTypeEquipement(forId: selectedEquipement.parentId)
            }
            self.initializeCustomSearchBar()
        } else {
            self.initSearchBar()
        }
    }
    
    // MARK: - Other functions
    func initSearchBar() {
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        // Put the search bar in the navigation bar.
        if let searchBar = searchController?.searchBar {
            searchBar.sizeToFit()
            searchBar.placeholder = Constants.PlaceHolder.saisirAdresse
            
            searchBar.tintColor = UIColor.white
            searchBar.isTranslucent = false
            
            self.perform(#selector(searchBarFirstResponder), with: nil, afterDelay: 0.1)
            
            view.addSubview(searchBar)
        }
        
        // Prevent the navigation bar from being hidden when searching.
        searchController?.hidesNavigationBarDuringPresentation = false
        
        // Active sur le filtre sur Paris uniquement
        MapsUtils.filterToParis(resultsViewController: self.resultsViewController!)
    }
    
    func initializeCustomSearchBar() {
        // Place the search bar view to the tableview headerview.
        if equipementSearchController == nil {
            let mapStoryboard = UIStoryboard(name: Constants.StoryBoard.map, bundle: nil)
            equipementSearchController = mapStoryboard.instantiateViewController(withIdentifier: "EquipementSearchTableViewController") as? EquipementSearchTableViewController
            
            equipementSearchController?.equipementDelegate = self
        }
        
        customSearchController = UISearchController(searchResultsController: equipementSearchController)
        customSearchController?.hidesNavigationBarDuringPresentation = false
        customSearchController?.searchBar.placeholder = self.typeEquipementSelected?.placeholder
        customSearchController?.searchBar.sizeToFit()
        
        equipementSearchController?.tableView.tableHeaderView = customSearchController?.searchBar
        customSearchController?.searchResultsUpdater = equipementSearchController
        
        view.addSubview((customSearchController?.searchBar)!)
        
        equipementSearchController?.equipements = ReferalManager.shared.getEquipements(forTypeEquipementId: (self.typeEquipementSelected?.typeEquipementId)!)!
        equipementSearchController?.equipements.sort(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending })
        equipementSearchController?.tableView.reloadData()
    }
    
    func searchBarFirstResponder() {
        self.searchController?.searchBar.becomeFirstResponder()
    }
}


// Handle the user's selection.
extension ModifyAddressViewController: GMSAutocompleteResultsViewControllerDelegate {
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        
        let geocoder = GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(place.coordinate) { (response: GMSReverseGeocodeResponse?, error: Error?) in
            if let error = error {
                print("Nothing found: \(error.localizedDescription)")
                return
            }
            if let addressFound = response {
                self.delegate.changeAddress(newAddress: addressFound.firstResult()! )
                 _ = self.navigationController?.popViewController(animated: true)
            }
        }
        
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}


extension ModifyAddressViewController: EquipementDelegate {
    func didSelectEquipementAt(equipement: Equipement) {
        customSearchController?.isActive = false
        
        self.delegate.changeEquipement(newEquipement: equipement)
         _ = self.navigationController?.popViewController(animated: true)
    }
}
