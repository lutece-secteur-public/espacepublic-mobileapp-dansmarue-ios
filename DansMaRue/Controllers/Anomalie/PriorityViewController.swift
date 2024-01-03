//
//  PriorityViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 06/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class PriorityViewController: UIViewController {
    // MARK: - Properties

    weak var delegate: AddAnomalyViewController!
    
    // MARK: - IBoutlets

    @IBOutlet var tableView: UITableView!
    
    // MARK: - View life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView?.isAccessibilityElement = true
        navigationItem.title = Constants.LabelMessage.priority
        navigationItem.leftBarButtonItem?.accessibilityLabel = Constants.AccessibilityLabel.backButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(backAction))
        if let image = UIImage(named: Constants.Image.iconBack) {
            navigationItem.leftBarButtonItem?.image = image
        }
        tableView.estimatedRowHeight = 45
        tableView.rowHeight = UITableView.automaticDimension
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
  
// MARK: Extension

extension PriorityViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate.changePriority(newPriority: Priority.allValues[indexPath.row])
        _ = navigationController?.popViewController(animated: true)
    }
}

extension PriorityViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Priority.allValues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "PriorityTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? PriorityTableViewCell else {
            fatalError("The dequeued cell is not an instance of PriorityTableViewCell.")
        }
        
        // Fetches the appropriate meal for the data source layout.
        cell.labelPriority.text = Priority.allValues[indexPath.row].description
        cell.labelPriority.adjustsFontForContentSizeCategory = true
        cell.labelPriority.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 14.0)
        
        return cell
    }
}
