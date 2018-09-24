//
//  EquipementSearchTableViewController.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 07/11/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

protocol EquipementDelegate: NSObjectProtocol {
    func didSelectEquipementAt(equipement: Equipement)
}

class EquipementSearchTableViewController: UITableViewController {

    // MARK: Properties
    var equipements = [Equipement]()
    var filteredEquipements = [Equipement]()
    
    weak var equipementDelegate: EquipementDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        //self.tableView.contentInset = UIEdgeInsetsMake(-10, 0, 0, 0);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 58
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows = filteredEquipements.count
        if filteredEquipements.isEmpty {
            let noDataLabel: UILabel     = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text          = Constants.LabelMessage.equipementSearchNotFound
            noDataLabel.textColor     = UIColor.greyDmr()
            noDataLabel.textAlignment = .center
            noDataLabel.lineBreakMode = .byWordWrapping
            noDataLabel.numberOfLines = 0
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none

            numberOfRows = 0
        }
        
        return numberOfRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...
        tableView.separatorStyle  = .singleLine
        tableView.backgroundView = nil
        
        let equipement = filteredEquipements[indexPath.row]
        if let equipementName = cell.viewWithTag(102) as? UILabel {
            equipementName.text = equipement.name
        }
        if let equipementAddress = cell.viewWithTag(103) as? UILabel {
            equipementAddress.text = equipement.adresse
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let equipement = filteredEquipements[indexPath.row]
        equipementDelegate?.didSelectEquipementAt(equipement: equipement)
    }
}

extension EquipementSearchTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            self.filteredEquipements = self.equipements.filter { equipement in
                return equipement.name.lowercased().contains(searchText.lowercased()) ||
                    equipement.name.lowercased().folding(options: .diacriticInsensitive, locale: .current).contains(searchText.lowercased()) ||
                    equipement.adresse.lowercased().contains(searchText.lowercased().folding(options: .diacriticInsensitive, locale: .current)) ||
                    equipement.adresse.lowercased().contains(searchText.lowercased())
            }
            
        } else {
            self.filteredEquipements = self.equipements
        }
        tableView.reloadData()
    }

}
