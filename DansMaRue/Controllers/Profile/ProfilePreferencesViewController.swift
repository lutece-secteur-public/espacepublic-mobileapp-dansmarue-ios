//
//  ProfilePreferencesViewController.swift
//  DansMaRue
//
//  Created by Maxime Bureau on 14/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class ProfilePreferencesViewController: UIViewController {

    //MARK: - Properties
    let preferencesArray = ["Recevoir les notifications par push", "Autoriser la géolocalisation", "Autoriser DansMaRue à accéder à ma caméra", "Autoriser DansMaRue à accéder à ma bibliothèque"]
    
    //MARK: - IBOutlets
    @IBOutlet weak var preferencesTableView: UITableView!
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferencesTableView.tableFooterView = UIView()
    }

}

extension ProfilePreferencesViewController: UITableViewDelegate {
    
}

extension ProfilePreferencesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let preferenceCell = tableView.dequeueReusableCell(withIdentifier: "preference_cell")
        let preferenceTitle = preferenceCell?.viewWithTag(101) as! UILabel
        preferenceTitle.text = preferencesArray[indexPath.row]
        
        return preferenceCell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return preferencesArray.count
    }
    
}
