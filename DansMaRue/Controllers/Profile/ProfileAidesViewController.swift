//
//  ProfileAidesViewController.swift
//  DansMaRue
//
//  Created by geoffroy.huet on 13/04/2022.
//  Copyright © 2022 VilleDeParis. All rights reserved.
//

import UIKit
import SafariServices

class ProfileAidesViewController: UIViewController, SFSafariViewControllerDelegate {
    
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var aidesTableView: UITableView!
    
    var aides = [Aide]()
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = Constants.TabBarTitle.monEspace
        subTitle.text = Constants.LabelMessage.aide
        
        if let aides =  ReferalManager.shared.getAides() {
            self.aides.append(contentsOf: aides)
        }
    }
}

extension ProfileAidesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aide = aides[indexPath.row]
        
        let aidesCell = tableView.dequeueReusableCell(withIdentifier: "aides_cell")
        
        let imageURL = URL(string: aide.imageUrl)
        let aideImageUrl = aidesCell?.viewWithTag(101) as! UIImageView
        aideImageUrl.sd_setImage(with: imageURL!, placeholderImage: nil, options: .allowInvalidSSLCertificates)
        
        let aideLabel = aidesCell?.viewWithTag(102) as! UILabel
        aideLabel.text = aide.libelle
               
        return aidesCell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return aides.count
    }
}

extension ProfileAidesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let aide = aides[indexPath.row]
        if let url = URL(string: aide.hypertexteUrl) {
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: true)
            vc.delegate = self

            present(vc, animated: true)
        }

    }
    
}
