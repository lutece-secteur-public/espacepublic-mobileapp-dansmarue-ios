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
                    types.append(type)
                }
            }
        }
        
        tableView.reloadData()
    }
    
    func backAction(){
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
}

extension TypeAnomalieViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {        
        typeAnomalie = types[indexPath.row]
        
        if typeAnomalie.childrensId.isEmpty {
            delegate.changeTypeAnomalie(newType: typeAnomalie)
            _ = navigationController?.popViewController(animated: true)
            
        } else {
            self.navigationItem.title = typeAnomalie.name
            self.reloadData(childrens: typeAnomalie.childrensId)
        }
        
    }
}

extension TypeAnomalieViewController: UITableViewDataSource {
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
        
        return cell
    }
}
