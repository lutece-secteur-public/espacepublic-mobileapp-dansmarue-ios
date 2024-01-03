//
//  ProfileActualitesViewController.swift
//  DansMaRue
//
//  Created by geoffroy.huet on 14/04/2022.
//  Copyright © 2022 VilleDeParis. All rights reserved.
//

import UIKit

class ProfileActualitesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet var subTitle: UILabel!
    @IBOutlet var actualitesTableView: UITableView!
    
    var actualites = [Actualite]()
    var rowSelected = -1
    var sectionsShow = Set<Int>()
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        actualitesTableView.delegate = self
        actualitesTableView.dataSource = self
        actualitesTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        actualitesTableView.estimatedRowHeight = 116
        actualitesTableView.estimatedSectionHeaderHeight = 116
        actualitesTableView.rowHeight = UITableView.automaticDimension
        actualitesTableView.sectionHeaderHeight = UITableView.automaticDimension
        
        title = Constants.TabBarTitle.monEspace
        subTitle.text = Constants.LabelMessage.actualites
        subTitle.isAccessibilityElement = true
        subTitle.textColor = UIColor.greyDmr()
        subTitle.accessibilityLabel = Constants.LabelMessage.actualites
        subTitle.accessibilityTraits = .header
        subTitle.adjustsFontForContentSizeCategory = true
        subTitle.font = UIFont.preferredFont(forTextStyle: .title3)
        
        if let actualites = ReferalManager.shared.getActualites() {
            self.actualites.append(contentsOf: actualites)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        actualitesTableView.layoutIfNeeded()
        actualitesTableView.reloadData()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigationItem.titleView)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let actualite = actualites[indexPath.section]
        let actualitesCell = tableView.dequeueReusableCell(withIdentifier: "actualites_cell")
        actualitesCell?.isAccessibilityElement = true
        actualitesCell?.accessibilityTraits = .staticText
        actualitesCell?.accessibilityLabel = actualite.texte.htmlToString
        let actualiteTexte = actualitesCell?.viewWithTag(102) as! UILabel
        actualiteTexte.isAccessibilityElement = true
        actualiteTexte.accessibilityTraits = .staticText
       
        let font = UIFont.systemFont(ofSize: 14)
        let attributes = [NSAttributedString.Key.font: font]
        _ = NSAttributedString(string: actualite.texte.htmlToString, attributes: attributes)
        actualiteTexte.attributedText = actualite.texte.htmlToAttributedString
        actualiteTexte.adjustsFontForContentSizeCategory = true
        actualiteTexte.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 18.0)
        return actualitesCell!
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return actualites.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sectionsShow.contains(section) {
            return 1
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableCell(withIdentifier: "header_cell")
        let actualite = actualites[section]
        let imageURL = URL(string: actualite.imageUrl)!
        let imageView = view?.viewWithTag(100) as! UIImageView
        let titleLabel = view?.viewWithTag(101) as! UILabel
        imageView.sd_setImage(with: imageURL, placeholderImage: nil, options: .allowInvalidSSLCertificates)
        imageView.isAccessibilityElement = false
        view?.isAccessibilityElement = true
        view?.accessibilityLabel = actualite.libelle
        view?.accessibilityTraits = .button
        titleLabel.text = actualite.libelle
        titleLabel.accessibilityTraits = .staticText
        titleLabel.tintColor = UIColor(hexString: "#C60")
        titleLabel.textColor = UIColor(hexString: "#C60")
        view?.tag = section
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.scaledFont(name: "Montserrat-Bold", textSize: 18.0)
        titleLabel.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(hideSection(_:)))
        gesture.numberOfTapsRequired = 1
        view?.addGestureRecognizer(gesture)
        
        return view
    }
    
    @objc
    private func hideSection(_ sender: UITapGestureRecognizer) {
        let section = sender.view?.tag ?? 0
        
        func indexPathsForSection() -> [IndexPath] {
            var indexPaths = [IndexPath]()
            indexPaths.append(IndexPath(row: 0, section: section))
            
            return indexPaths
        }
        
        if !sectionsShow.contains(section) {
            sectionsShow.insert(section)
            actualitesTableView.insertRows(at: indexPathsForSection(), with: .fade)
            actualitesTableView.reloadData()
        } else {
            sectionsShow.remove(section)
            actualitesTableView.deleteRows(at: indexPathsForSection(), with: .fade)
            actualitesTableView.reloadData()
        }
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }

    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}
