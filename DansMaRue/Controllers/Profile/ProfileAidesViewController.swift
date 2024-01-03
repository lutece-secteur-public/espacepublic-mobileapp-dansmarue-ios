//
//  ProfileAidesViewController.swift
//  DansMaRue
//
//  Created by geoffroy.huet on 13/04/2022.
//  Copyright © 2022 VilleDeParis. All rights reserved.
//

import SafariServices
import UIKit

class ProfileAidesViewController: UIViewController, SFSafariViewControllerDelegate {
    @IBOutlet var subTitle: UILabel!
    @IBOutlet var aidesTableView: UITableView!

    var aides = [Aide]()

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        aidesTableView.delegate = self
        aidesTableView.dataSource = self
        aidesTableView.estimatedRowHeight = 116
        aidesTableView.rowHeight = UITableView.automaticDimension
        title = Constants.TabBarTitle.monEspace
        subTitle.text = Constants.LabelMessage.aide
        subTitle.isAccessibilityElement = true
        subTitle.textColor = UIColor.greyDmr()
        subTitle.accessibilityLabel = Constants.LabelMessage.aide
        subTitle.accessibilityTraits = .header
        subTitle.adjustsFontForContentSizeCategory = true
        subTitle.font = UIFont.preferredFont(forTextStyle: .title3)
        if let aides = ReferalManager.shared.getAides() {
            self.aides.append(contentsOf: aides)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigationItem.titleView)
        aidesTableView.layoutIfNeeded()
        aidesTableView.reloadData()
    }
}

extension ProfileAidesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aide = aides[indexPath.row]

        let aidesCell = tableView.dequeueReusableCell(withIdentifier: "aides_cell")
        aidesCell!.isAccessibilityElement = true
        aidesCell!.accessibilityTraits = .link
        let imageURL = URL(string: aide.imageUrl)
        let aideImageUrl = aidesCell?.viewWithTag(101) as! UIImageView
        aideImageUrl.isAccessibilityElement = false
        aideImageUrl.sd_setImage(with: imageURL!, placeholderImage: nil, options: .allowInvalidSSLCertificates)

        let aideLabel = aidesCell?.viewWithTag(102) as! UILabel
        aideLabel.text = aide.libelle
        aideLabel.accessibilityLabel = aide.libelle
        aideLabel.adjustsFontForContentSizeCategory = true
        aideLabel.font = UIFont.scaledFont(name: "Montserrat-Bold", textSize: 18.0)
        aideLabel.textColor = UIColor(hexString: "#C60")
        aidesCell?.setNeedsUpdateConstraints()
        aidesCell?.updateConstraintsIfNeeded()
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
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
            vc.delegate = self

            present(vc, animated: true)
        }
    }
}
