//
//  ManageAddressViewController.swift
//  DansMaRue
//
//  Created by geoffroy.huet on 14/08/2019.
//  Copyright © 2019 VilleDeParis. All rights reserved.
//

import CoreLocation
import UIKit

class ManageAddressViewController: UIViewController {
    weak var delegate: MapViewController!
    var isModification = false
    var items: [String] = []
    
    // MARK: IBOutlet

    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var deleteButton: UIButton!

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.backgroundColor = UIColor.pinkDmr()

            navigationItem.standardAppearance = appearance
            navigationItem.scrollEdgeAppearance = appearance
        }
        navigationItem.title = Constants.LabelMessage.adressesFavorites
        navigationItem.titleView?.tintColor = .white
        items = getFavoritesAddress()
        tableView.dataSource = self
        tableView.isEditing = false
        tableView.estimatedRowHeight = 91
        tableView.rowHeight = UITableView.automaticDimension
        
        delegate.searchController?.isActive = false
        // Put the search bar in the navigation bar.
        if let searchBar = delegate.searchController?.searchBar {
            searchBar.placeholder = Constants.PlaceHolder.saisirAdresse
            
            searchBar.tintColor = UIColor.white
            searchBar.isTranslucent = false
            if #available(iOS 13.0, *) {
                searchBar.searchTextField.backgroundColor = UIColor.white
                searchBar.searchTextField.tintColor = UIColor.black
            }
            
            searchBar.layer.cornerRadius = 10
            delegate.setNavigationTitleView(withSearchBarController: delegate.searchController!)
        }
        applyDynamicType(label: deleteButton.titleLabel!, fontName: Constants.fontDmr, size: 16)
    }
    
    @IBAction func modifier(_ sender: Any) {
        isModification = !isModification
        tableView.isEditing = isModification
        tableView.reloadData()
        let deleteAllButton = tableView.viewWithTag(101) as! UIButton
        
        if isModification {
            navigationItem.rightBarButtonItem?.title = "Terminer"
        } else {
            navigationItem.rightBarButtonItem?.title = "Modifier"
        }
        
        deleteAllButton.isHidden = !isModification || items.count == 0
    }
    
    @IBAction func deleteAll(_ sender: Any) {
        items.removeAll()
        tableView.reloadData()
        
        // Sauvegarde des favoris MAJ
        let defaults = UserDefaults.standard
        defaults.set(items, forKey: "favoritesAddressArray")
        
        hideDeleteAllIfNoAddress()
    }

    private func applyDynamicType(label: UILabel, fontName: String, size: Float) {
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.scaledFont(name: fontName, textSize: CGFloat(size))
    }
}

// Retourne les adresses favorites de l'utilisateur, stockées sous la forme libelle***lat-long
func getFavoritesAddress() -> [String] {
    let defaults = UserDefaults.standard
    var favorite: [String] = []
    
    // Récupération des favoris dans les UserDefaults
    if let favoritesArray = defaults.stringArray(forKey: "favoritesAddressArray") {
        favorite = favoritesArray
    }
    return favorite
}

extension ManageAddressViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressTableViewCell")
        let adresseLabel = cell?.viewWithTag(100) as? UILabel
        let addressArr = items[indexPath.row].components(separatedBy: Constants.Key.separatorAdresseCoordonate)
        applyDynamicType(label: adresseLabel!, fontName: "Montserrat-Regular", size: 15)
        if addressArr.count == 2 {
            adresseLabel?.text = addressArr[0].trimmingCharacters(in: .whitespaces)
        }
        
        return cell!
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (items.count)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let favorite = items[indexPath.row]
        print(favorite)
        
        let addressArr = items[indexPath.row].components(separatedBy: Constants.Key.separatorAdresseCoordonate)
        if addressArr.count == 2 {
            let coordArr = addressArr[1].components(separatedBy: "-")
            if coordArr.count == 2 {
                _ = navigationController?.popViewController(animated: true)
                let currentLocation = CLLocationCoordinate2D(latitude: Double(coordArr[0])!, longitude: Double(coordArr[1])!)
                delegate.centerCameraToPosition(currentLocation: currentLocation)
                delegate.retrieve(currentLocation: currentLocation, addMarker: true, address: addressArr[0]) { (_: Bool) in }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.tableView.isEditing
    }
    
    // Modification de l'ordre des favoris
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Modification de l'ordre des favoris
        let itemToMove = items[sourceIndexPath.row]
        items.remove(at: sourceIndexPath.row)
        items.insert(itemToMove, at: destinationIndexPath.row)
        
        // Sauvegarde du nouvel ordre
        let defaults = UserDefaults.standard
        defaults.set(items, forKey: "favoritesAddressArray")
    }
    
    // Suppression de favoris
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            items.remove(at: indexPath.row)
            tableView.reloadData()
            tableView.endUpdates()
            
            // Sauvegarde des favoris MAJ
            let defaults = UserDefaults.standard
            defaults.set(items, forKey: "favoritesAddressArray")
            
            hideDeleteAllIfNoAddress()
        }
    }
    
    // Cache le bouton "tout supprimer" si il n'y a plus de favoris
    func hideDeleteAllIfNoAddress() {
        if items.count == 0 {
            let deleteAllButton = tableView.viewWithTag(101) as! UIButton
            deleteAllButton.isHidden = true
        }
    }
}
