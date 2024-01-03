//
//  TypeAnomalieViewController.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 30/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import SwiftyJSON
import UIKit

class TypeAnomalieViewController: UIViewController {
    // MARK: Properties

    var types = [TypeAnomalie]()
    var typesSearch = [TypeAnomalie]()
    var typeAnomalie = TypeAnomalie()
    weak var delegate: AddAnomalyViewController!
    var searching: Bool? = false
    
    // MARK: IBOutlet

    // @IBOutlet var searchTextField: FloatingLabelInput!
    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var titleFloatingLabel: UILabel!
    //   @IBOutlet var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.pinkDmr()
        tableView.tableFooterView = UIView()
        titleFloatingLabel.adjustsFontForContentSizeCategory = true
        titleFloatingLabel.accessibilityTraits = .staticText
        titleFloatingLabel.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 12.0)
        titleFloatingLabel.text = Constants.PlaceHolder.searchType
        titleFloatingLabel.isHidden = true
        navigationItem.title = Constants.AccessibilityLabel.typeTitle
        navigationItem.isAccessibilityElement = true
        navigationItem.titleView?.isAccessibilityElement = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(backAction))
        navigationItem.leftBarButtonItem?.accessibilityTraits = .button
        navigationItem.leftBarButtonItem?.accessibilityLabel = Constants.AccessibilityLabel.backButton
        navigationItem.rightBarButtonItem?.accessibilityLabel = Constants.AccessibilityLabel.favoriteTypesButton
        navigationItem.rightBarButtonItem?.accessibilityTraits = .button
        if let image = UIImage(named: Constants.Image.iconBack) {
            navigationItem.leftBarButtonItem?.image = image
        }

        loadRootTypes()
    }
    
    @IBAction func openFavorites(_ sender: Any) {
        let typeVC = UIStoryboard(name: Constants.StoryBoard.manageFavorites, bundle: nil).instantiateInitialViewController() as! ManageFavoritesViewController
        typeVC.delegate = self
        navigationController?.pushViewController(typeVC, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigationItem.titleView)
        searchTextField.isAccessibilityElement = true
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(textFieldDidChange(_:)),
                                  for: .editingChanged)
        
        searchTextField.placeholder = Constants.PlaceHolder.searchType
        searchTextField.accessibilityLabel = Constants.PlaceHolder.searchType
        searchTextField.accessibilityTraits = .searchField
        searchTextField.accessibilityHint = Constants.AccessibilityHint.searchBarTypeHint
    }

    // MARK: Other Methods

    private func loadRootTypes() {
        if delegate.typeContribution == .indoor {
            reloadData(childrens: (ContextManager.shared.typeEquipementSelected?.categoriesAnomaliesId)!)
        } else {
            if let array = UserDefaults.standard.array(forKey: Constants.Key.categorieList) {
                reloadData(childrens: array as! [String])
            }
        }
    }
    
    private func scrollToFirstRow() {
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
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
                if let type = ReferalManager.shared.getTypeAnomalie(withId: childrenId) {
                    // Vérification des catégories destinées aux agents
                    let isAgent = User.shared.isAgent
                    if type.isAgent && (isAgent != nil && isAgent!) {
                        types.append(type)
                    } else if !type.isAgent {
                        types.append(type)
                    }
                }
            }
        }
        
        tableView.reloadData()
        scrollToFirstRow()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigationItem.titleView)
    }
    
    @objc func backAction() {
        if typeAnomalie.parentId.isEmpty {
            _ = navigationController?.popViewController(animated: true)
        } else if typeAnomalie.isRootCategorie {
            loadRootTypes()
            typeAnomalie = TypeAnomalie()
            let label = UILabel()
            label.backgroundColor = .clear
            label.numberOfLines = 0
            label.textColor = .white
            label.text = Constants.LabelMessage.typeBackButton
            label.isAccessibilityElement = true
            label.accessibilityLabel = Constants.LabelMessage.typeBackButton
            label.accessibilityTraits = .header
            label.font = UIFont.boldSystemFont(ofSize: 16.0)
            navigationItem.titleView = label
        } else {
            if delegate.typeContribution == .indoor {
                guard let typeEquipementId = ContextManager.shared.typeEquipementSelected?.typeEquipementId else { return }
                if let type = ReferalManager.shared.getTypeAnomalie(forTypeEquipementId: typeEquipementId, catagorieId: typeAnomalie.parentId) {
                    reloadData(childrens: type.childrensId)
                    typeAnomalie = type
                    navigationItem.title = type.name
                }
            } else {
                if let type = ReferalManager.shared.getTypeAnomalie(withId: typeAnomalie.parentId) {
                    reloadData(childrens: type.childrensId)
                    typeAnomalie = type
                    navigationItem.title = type.name
                }
            }
        }
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else { return }
        if text.count >= 3 {
            searching = true
            
            typesSearch.removeAll()
            
            let typesSelected = ReferalManager.shared.getAnomalieThatContainsText(type: text)
            if typesSelected != nil {
                typesSearch = typesSelected!
            }
            tableView.reloadData()
        } else {
            searching = false
            tableView.reloadData()
        }
    }

    func changeTypeAnomalie(newType: TypeAnomalie) {
        delegate.changeTypeAnomalie(newType: newType)
        _ = navigationController?.popViewController(animated: true)
    }
}

extension TypeAnomalieViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searching! {
            typeAnomalie = typesSearch[indexPath.row]
        } else {
            typeAnomalie = types[indexPath.row]
        }
        
        if typeAnomalie.childrensId.isEmpty {
            // Si type d'ano avec message
            if typeAnomalie.messageBO != "" {
                let messageTypeAnoStoryboard = UIStoryboard(name: Constants.StoryBoard.messageTypeAno, bundle: nil)
                let messageTypeAnoVC = messageTypeAnoStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.messageTypeAno) as! MessageTypeAnoViewController
                // Passage du type d'anomalie au controller
                messageTypeAnoVC.typeAnomalie = typeAnomalie
                
                navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                navigationController?.pushViewController(messageTypeAnoVC, animated: true)
            } else {
                // Sinon selection du type d'ano
                delegate.changeTypeAnomalie(newType: typeAnomalie)
                _ = navigationController?.popViewController(animated: true)
            }
        } else {
            let label = UILabel()
            label.backgroundColor = .clear
            label.numberOfLines = 0
            label.textColor = .white
            label.text = typeAnomalie.name
            label.font = UIFont.boldSystemFont(ofSize: 16.0)
            navigationItem.titleView = label
            reloadData(childrens: typeAnomalie.childrensId)
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
        if !searching! {
            return types.count
        } else {
            return typesSearch.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "TypeTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TypeTableViewCell else {
            fatalError("The dequeued cell is not an instance of TypeTableViewCell.")
        }
        cell.typeFavorite.isAccessibilityElement = true
        cell.typeFavorite.accessibilityTraits = .button
        
        cell.typeLabel.isAccessibilityElement = true
        cell.typeLabel.accessibilityTraits = .staticText
        cell.typeLabel.adjustsFontForContentSizeCategory = true
        cell.typeLabel.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 14.0)
        
        if !searching! {
            let typeAnomalie = types[indexPath.row]
            
            cell.typeLabel.text = typeAnomalie.name
            cell.typeLabel.lineBreakMode = .byWordWrapping
            cell.typeLabel.numberOfLines = 0
            cell.typeImage.image = typeAnomalie.image
            cell.typeImage.isAccessibilityElement = false
            cell.typeImage.accessibilityTraits = .image
            
            // Gestion des favoris si on est sur le dernier niveau d'ano
            if typeAnomalie.childrensId.isEmpty {
                // Check si le type est enregistré en favoris
                var favorite: [String] = []
                let defaults = UserDefaults.standard
              
                // Tap gesture
                let recognizer = MyTapGesture(target: self, action: #selector(TypeAnomalieViewController.addOrRemoveFavorite(recognizer:)))
                recognizer.categorieId = typeAnomalie.categorieId
                
                if let favoritesArray = defaults.stringArray(forKey: "favoritesArray") {
                    favorite = favoritesArray
                }
                
                // Le type est déjà dans les favoris -> suppression
                if favorite.contains(typeAnomalie.categorieId) {
                    cell.typeFavorite.image = UIImage(named: Constants.Image.favoriteCheck)
                    cell.typeFavorite.accessibilityLabel = String(format: Constants.LabelMessage.removeTypeFavorite, typeAnomalie.name)
                    recognizer.addFavorite = false
                } else {
                    // Ajout au favoris
                    cell.typeFavorite.image = UIImage(named: Constants.Image.favoriteUncheck)
                    cell.typeFavorite.accessibilityLabel = String(format: Constants.LabelMessage.addTypeFavorite, typeAnomalie.name)
                    recognizer.addFavorite = true
                }
                // Add tap gesture recognizer to favorite image
                cell.typeFavorite.addGestureRecognizer(recognizer)
            } else {
                cell.typeFavorite.image = nil
                cell.typeFavorite.isAccessibilityElement = false
            }
        } else {
            let typeAnomalie = typesSearch[indexPath.row]
            cell.typeLabel.text = typeAnomalie.name
            cell.typeLabel.accessibilityLabel = typeAnomalie.name
            cell.typeLabel.lineBreakMode = .byWordWrapping
            cell.typeLabel.numberOfLines = 0
            cell.typeFavorite.image = nil
            cell.typeImage.image = nil
            cell.typeFavorite.isAccessibilityElement = false
            
            // Gestion des favoris si on est sur le dernier niveau d'ano
            if typeAnomalie.childrensId.isEmpty {
                // Check si le type est enregistré en favoris
                var favorite: [String] = []
                let defaults = UserDefaults.standard
              
                // Tap gesture
                let recognizer = MyTapGesture(target: self, action: #selector(TypeAnomalieViewController.addOrRemoveFavorite(recognizer:)))
                recognizer.categorieId = typeAnomalie.categorieId
                
                if let favoritesArray = defaults.stringArray(forKey: "favoritesArray") {
                    favorite = favoritesArray
                }
                
                // Le type est déjà dans les favoris -> suppression
                if favorite.contains(typeAnomalie.categorieId) {
                    cell.typeFavorite.image = UIImage(named: Constants.Image.favoriteCheck)
                    cell.typeFavorite.accessibilityLabel = Constants.LabelMessage.removeTypeFavorite
                    recognizer.addFavorite = false
                } else {
                    // Ajout au favoris
                    cell.typeFavorite.image = UIImage(named: Constants.Image.favoriteUncheck)
                    cell.typeFavorite.accessibilityLabel = Constants.LabelMessage.addTypeFavorite
                    recognizer.addFavorite = true
                }
                // Add tap gesture recognizer to favorite image
                cell.typeFavorite.addGestureRecognizer(recognizer)
            }
        }
        return cell
    }
    
    // Add/remove favorite
    @objc func addOrRemoveFavorite(recognizer: MyTapGesture) {
        var favorite: [String] = []
        let defaults = UserDefaults.standard
        
        if let favoritesArray = defaults.stringArray(forKey: "favoritesArray") {
            favorite = favoritesArray
        }
        
        if recognizer.addFavorite {
            // Ajout du favoris
            favorite.append(recognizer.categorieId)
        } else {
            // Suppression du favoris
            if let index = favorite.index(of: recognizer.categorieId) {
                favorite.remove(at: index)
            }
        }
        defaults.set(favorite, forKey: "favoritesArray")
        tableView.reloadData()
    }
    
    // Class tapeGesture perso pour envoyre l'id en param
    class MyTapGesture: UITapGestureRecognizer {
        var categorieId = String()
        var addFavorite = Bool()
    }
}

extension TypeAnomalieViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        UIView.animate(withDuration: 0.25, animations: { () in
            self.titleFloatingLabel.isHidden = false
        })
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.25, animations: { () in
            self.titleFloatingLabel.isHidden = true
        })
    }
}
