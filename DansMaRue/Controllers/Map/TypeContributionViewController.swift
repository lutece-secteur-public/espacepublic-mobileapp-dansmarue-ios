//
//  TypeContributionViewController.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 30/10/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class TypeContributionViewController: UIViewController {
    var types = [TypeEquipement]()
    weak var delegate: MapViewController!
    
    enum RowId {
        static let espacePublic = 0
        static let equipement = 1
        static let other = 2
    }
    
    // MARK: IBOutlets

    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        tableView.tableFooterView = UIView()
        
        navigationItem.title = Constants.LabelMessage.typeContributionLabel
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(backAction))
        if let image = UIImage(named: Constants.Image.iconExit) {
            navigationItem.leftBarButtonItem?.image = image
        }
        
        types.append(contentsOf: ReferalManager.shared.typeEquipements.values)
    }
    
    // MARK: Other Methods

    @objc func backAction() {
        _ = navigationController?.popViewController(animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigationItem.titleView)
    }
}

extension TypeContributionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case RowId.espacePublic:
            ContextManager.shared.typeContribution = .outdoor
            delegate.changeTypeContribution(withName: Constants.LabelMessage.defaultTypeContributionLabel)
        default:
            ContextManager.shared.typeContribution = .indoor
            ContextManager.shared.typeEquipementSelected = types[indexPath.row - 1]
            delegate.changeTypeContribution(withName: types[indexPath.row - 1].name)
        }
        _ = navigationController?.popViewController(animated: true)
    }
}

extension TypeContributionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return types.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = tableView.dequeueReusableCell(withIdentifier: "TypeTableViewCell")
        
        let imageCell = defaultCell?.viewWithTag(110) as? UIImageView
        let typeLabel = defaultCell?.viewWithTag(120) as? UILabel
        
        switch indexPath.row {
        case RowId.espacePublic:
            typeLabel?.text = Constants.LabelMessage.defaultTypeContributionLabel
            imageCell?.image = UIImage(named: Constants.Image.iconEspacePublic)
        default:
            let typeEquipement = types[indexPath.row - 1]
            typeLabel?.text = typeEquipement.name
            imageCell?.image = typeEquipement.image
        }
        
        return defaultCell!
    }
}
