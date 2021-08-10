//
//  ManageFavoritesViewController
//  DansMaRue
//
//  Created by geoffroy.huet on 13/08/2019.
//  Copyright © 2019 VilleDeParis. All rights reserved.
//

import UIKit

class ManageFavoritesViewController: UIViewController {
    //MARK: Properties
    weak var delegate: TypeAnomalieViewController!
    var isModification = false
    
    //MARK: IBOutlet
    @IBOutlet weak var tableView: UITableView!
    
    var items: [String] = []
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = Constants.LabelMessage.typeFavoris
        items = getFavorites()
        tableView.dataSource = self
    }
    
    //Tap sur le bouton de modification
    @IBAction func modifier(_ sender: Any) {
        isModification = !isModification
        self.tableView.isEditing = isModification
        let deleteAllButton = self.tableView.viewWithTag(101) as! UIButton
        
        if isModification {
            self.navigationItem.rightBarButtonItem?.title = "Terminer"
        } else {
            self.navigationItem.rightBarButtonItem?.title = "Modifier"
        }
        deleteAllButton.isHidden = !isModification || items.count==0
    }
    
    @IBAction func deleteAll(_ sender: Any) {
        items.removeAll()
        tableView.reloadData()
        
        //Sauvegarde des favoris MAJ
        let defaults = UserDefaults.standard
        defaults.set(items, forKey: "favoritesArray")
        delegate.tableView.reloadData()
        
        hideDeleteAllIfNoAddress()
    }
    
    
}


extension ManageFavoritesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let typeAnomalie = items[indexPath.row]
        print(typeAnomalie)
        if let typeAno = ReferalManager.shared.getTypeAnomalie(withId: typeAnomalie) {            
            //Si type d'ano avec message
            if typeAno.messageBO != "" {
                let messageTypeAnoStoryboard = UIStoryboard(name: Constants.StoryBoard.messageTypeAno, bundle: nil)
                let messageTypeAnoVC = messageTypeAnoStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.messageTypeAno) as! MessageTypeAnoViewController
                //Passage du type d'anomalie au controller
                messageTypeAnoVC.typeAnomalie = typeAno
                
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                self.navigationController?.pushViewController(messageTypeAnoVC, animated: true)
            } else {
                //Sinon selection du type d'ano
                delegate.changeTypeAnomalie(newType: typeAno)
                _ = navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (items.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "TypeFavoritesTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TypeFavoritesTableViewCell  else {
            fatalError("The dequeued cell is not an instance of TypeFavoritesTableViewCell.")
        }
        
        if let typeAnomalie = ReferalManager.shared.getTypeAnomalie(withId: items[indexPath.row]){
            cell.typeLabel.text = typeAnomalie.alias
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
       return self.tableView.isEditing
    }
    
    //Modification de l'ordre des favoris
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        //Modification de l'ordre des favoris
        let itemToMove = items[sourceIndexPath.row]
        items.remove(at: sourceIndexPath.row)
        items.insert(itemToMove, at: destinationIndexPath.row)
        
        //Sauvegarde du nouvel ordre
        let defaults = UserDefaults.standard
        defaults.set(items, forKey: "favoritesArray")
    }
    
    //Suppression de favoris
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print(indexPath)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            items.remove(at: indexPath.row)
            tableView.reloadData()
            tableView.endUpdates()
            
            //Sauvegarde des favoris MAJ
            let defaults = UserDefaults.standard
            defaults.set(items, forKey: "favoritesArray")
            
            delegate.tableView.reloadData()
            
            hideDeleteAllIfNoAddress()
        }
    }
    
    //Cache le bouton "tout supprimer" si il n'y a plus de favoris
    func hideDeleteAllIfNoAddress() {
        if(items.count==0) {
            let deleteAllButton = self.tableView.viewWithTag(101) as! UIButton
            deleteAllButton.isHidden = true
        }
    }
}

//Retourne les type favoris de l'utilisateur
private func getFavorites() -> [String] {
    var favorite : [String] = []
    let defaults = UserDefaults.standard
    
    //Récupération des favoris dans les UserDefaults
    if let favoritesArray = defaults.stringArray(forKey: "favoritesArray") {
        //On ne garde que les types toujours présents dans le BO
        for typeFavorite in favoritesArray {
            if let type = ReferalManager.shared.getTypeAnomalie(withId: typeFavorite) {
                favorite.append(type.categorieId)
            }
        }
        defaults.set(favorite, forKey: "favoritesArray")
    }
    
    return favorite
}
