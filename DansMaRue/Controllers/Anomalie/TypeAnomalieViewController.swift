//
//  TypeAnomalieViewController.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 30/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit
import SwiftyJSON

class TypeAnomalieViewController: UIViewController {

    //MARK: Properties
    var types = [TypeAnomalie]()
    var typeAnomalie = TypeAnomalie()
    weak var delegate: AddAnomalyViewController!
    
    //MARK: IBOutlet
    @IBOutlet weak var tableView: UITableView!
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()

        self.navigationItem.title = Constants.LabelMessage.type
        //self.navigationItem.backBarButtonItem?.title = ""
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(backAction))
        if let image = UIImage(named: Constants.Image.iconBack) {
            navigationItem.leftBarButtonItem?.image = image
        }

        loadRootTypes()
    }
    
    @IBAction func openFavorites(_ sender: Any) {
        let typeVC = UIStoryboard(name: Constants.StoryBoard.manageFavorites, bundle: nil).instantiateInitialViewController() as! ManageFavoritesViewController
        typeVC.delegate = self
        self.navigationController?.pushViewController(typeVC, animated: true)
    }
    
    //MARK: Other Methods
    private func loadRootTypes() {
        if delegate.typeContribution == .indoor {
            reloadData(childrens: (ContextManager.shared.typeEquipementSelected?.categoriesAnomaliesId)!)
        } else {
            if let array = UserDefaults.standard.array(forKey: Constants.Key.categorieList) {
                reloadData(childrens: array as! [String])
            }
        }
    }
    
    func reloadData(childrens: [String]) {
        types.removeAll()
        
        if delegate.typeContribution == .indoor {
            guard let typeEquipementId = ContextManager.shared.typeEquipementSelected?.typeEquipementId else { return }
            for childrenId in childrens {
                if let type = ReferalManager.shared.getTypeAnomalie(forTypeEquipementId: typeEquipementId, catagorieId: childrenId) {
                    types.append(type)
                }
            }
        } else {
            for childrenId in childrens {
                if let type =  ReferalManager.shared.getTypeAnomalie(withId: childrenId) {
                    // Vérification des catégories destinées aux agents
                    let isAgent = User.shared.isAgent
                    if ( type.isAgent && (isAgent != nil && isAgent!) ) {
                        types.append(type)
                    } else if !type.isAgent {
                        types.append(type)
                    }
                    
                }
            }
        }
        
        tableView.reloadData()
    }
    
    @objc func backAction(){
        if typeAnomalie.parentId.isEmpty {
            _ = navigationController?.popViewController(animated: true)
        } else if typeAnomalie.isRootCategorie {
            loadRootTypes()
            typeAnomalie = TypeAnomalie()
            self.navigationItem.title = Constants.LabelMessage.type
        } else {
            if delegate.typeContribution == .indoor {
                guard let typeEquipementId = ContextManager.shared.typeEquipementSelected?.typeEquipementId else { return }
                if let type = ReferalManager.shared.getTypeAnomalie(forTypeEquipementId: typeEquipementId, catagorieId:  typeAnomalie.parentId) {
                    reloadData(childrens: type.childrensId)
                    typeAnomalie = type
                    self.navigationItem.title = type.name
                }
            } else {
                if let type =  ReferalManager.shared.getTypeAnomalie(withId: typeAnomalie.parentId) {
                    reloadData(childrens: type.childrensId)
                    typeAnomalie = type
                    self.navigationItem.title = type.name
                }
            }
            
        }
    }
    
    func changeTypeAnomalie(newType:TypeAnomalie) {
        delegate.changeTypeAnomalie(newType: newType)
        _ = navigationController?.popViewController(animated: true)
    }
}

extension TypeAnomalieViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {        
        typeAnomalie = types[indexPath.row]
        
        if typeAnomalie.childrensId.isEmpty {
            //Si type d'ano avec message
            if typeAnomalie.messageBO != "" {
                let messageTypeAnoStoryboard = UIStoryboard(name: Constants.StoryBoard.messageTypeAno, bundle: nil)
                let messageTypeAnoVC = messageTypeAnoStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.messageTypeAno) as! MessageTypeAnoViewController
                //Passage du type d'anomalie au controller
                messageTypeAnoVC.typeAnomalie = typeAnomalie
                
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                self.navigationController?.pushViewController(messageTypeAnoVC, animated: true)
            } else {
                //Sinon selection du type d'ano
                delegate.changeTypeAnomalie(newType: typeAnomalie)
                _ = navigationController?.popViewController(animated: true)
            }
        } else {
            self.navigationItem.title = typeAnomalie.name
            self.reloadData(childrens: typeAnomalie.childrensId)
        }
        
    }
}

extension TypeAnomalieViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return UITableView.automaticDimension
        } else {
            return 40
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return UITableView.automaticDimension
        } else {
            return 40
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return types.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "TypeTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TypeTableViewCell  else {
            fatalError("The dequeued cell is not an instance of TypeTableViewCell.")
        }
        
        let typeAnomalie = types[indexPath.row]
        
        cell.typeLabel.text = typeAnomalie.name
        cell.typeLabel.lineBreakMode = .byWordWrapping
        cell.typeLabel.numberOfLines = 0
        
        cell.typeImage.image = typeAnomalie.image
        
        //Gestion des favoris si on est sur le dernier niveau d'ano
        if typeAnomalie.childrensId.isEmpty {
            //Check si le type est enregistré en favoris
            var favorite : [String] = []
            let defaults = UserDefaults.standard
          
            // Tap gesture
            let recognizer = MyTapGesture(target: self, action: #selector(TypeAnomalieViewController.addOrRemoveFavorite(recognizer:)))
            recognizer.categorieId = typeAnomalie.categorieId
            
            if let favoritesArray = defaults.stringArray(forKey: "favoritesArray") {
                favorite = favoritesArray
            }
            
            //Le type est déjà dans les favoris -> suppression
            if (favorite.contains(typeAnomalie.categorieId)) {
                cell.typeFavorite.image = UIImage(named:Constants.Image.favoriteCheck)
                recognizer.addFavorite = false
            } else {
                //Ajout au favoris
                cell.typeFavorite.image = UIImage(named:Constants.Image.favoriteUncheck)
                recognizer.addFavorite = true
            }
            // Add tap gesture recognizer to favorite image
            cell.typeFavorite.addGestureRecognizer(recognizer)
        } else {
            cell.typeFavorite.image = nil
        }
        
        return cell
    }
    
    //Add/remove favorite
    @objc func addOrRemoveFavorite(recognizer: MyTapGesture) {
        var favorite : [String] = []
        let defaults = UserDefaults.standard
        
        if let favoritesArray = defaults.stringArray(forKey: "favoritesArray") {
            favorite = favoritesArray
        }
        
        if(recognizer.addFavorite) {
            //Ajout du favoris
            favorite.append(recognizer.categorieId)
        } else {
            //Suppression du favoris
            if let index = favorite.index(of: recognizer.categorieId) {
                favorite.remove(at: index)
            }
        }
        defaults.set(favorite, forKey: "favoritesArray")
        tableView.reloadData()
    }
    
    //Class tapeGesture perso pour envoyre l'id en param
    class MyTapGesture: UITapGestureRecognizer {
        var categorieId = String()
        var addFavorite = Bool()
    }
    
}
