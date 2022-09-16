//
//  ProfileActualitesViewController.swift
//  DansMaRue
//
//  Created by geoffroy.huet on 14/04/2022.
//  Copyright © 2022 VilleDeParis. All rights reserved.
//

import UIKit

class ProfileActualitesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var actualitesTableView: UITableView!
    
    var actualites = [Actualite]()
    var rowSelected = -1
    var sectionsShow = Set<Int>()
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        actualitesTableView.register(SectionCustomHeader.self, forHeaderFooterViewReuseIdentifier: "sectionHeader")
        
        self.actualitesTableView.delegate = self
        self.actualitesTableView.dataSource = self
        self.actualitesTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        self.title = Constants.TabBarTitle.monEspace
        subTitle.text = Constants.LabelMessage.actualites
        
        if let actualites =  ReferalManager.shared.getActualites() {
            self.actualites.append(contentsOf: actualites)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let actualite = actualites[indexPath.section]
        let actualitesCell = tableView.dequeueReusableCell(withIdentifier: "actualites_cell")
        let actualiteTexte = actualitesCell?.viewWithTag(102) as! UILabel
       
        let font = UIFont.systemFont(ofSize: 14)
        let attributes = [NSAttributedString.Key.font: font]
        let attributedQuote = NSAttributedString(string: actualite.texte.htmlToString, attributes: attributes)
        actualiteTexte.attributedText = actualite.texte.htmlToAttributedString
        
        return actualitesCell!
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return actualites.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.sectionsShow.contains(section) {
            return 1
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "sectionHeader") as! SectionCustomHeader
        let actualite = actualites[section]
        let imageURL = URL(string: actualite.imageUrl)!
        
        view.image.sd_setImage(with: imageURL, placeholderImage: nil, options: .allowInvalidSSLCertificates)
        
        view.sectionTitle.setTitle(actualite.libelle, for: .normal)
        view.sectionTitle.setTitleColor(UIColor.orange, for: .normal)
        view.sectionTitle.addTarget(self,action: #selector(self.hideSection(sender:)),for: .touchUpInside)
        view.sectionTitle.tag = section
        view.sectionTitle.addTarget(self,action: #selector(self.hideSection(sender:)),for: .touchUpInside)
        view.sectionTitle.titleLabel!.numberOfLines = 0;
        view.sectionTitle.titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping;
        
        return view
    }
    
    @objc
    private func hideSection(sender: UIButton) {
        let section = sender.tag
        
        func indexPathsForSection() -> [IndexPath] {
            var indexPaths = [IndexPath]()
            indexPaths.append(IndexPath(row: 0, section: section))
            
            return indexPaths
        }
        
        if !self.sectionsShow.contains(section) {
            self.sectionsShow.insert(section)
            self.actualitesTableView.insertRows(at: indexPathsForSection(), with: .fade)
        } else {
            self.sectionsShow.remove(section)
            self.actualitesTableView.deleteRows(at: indexPathsForSection(), with: .fade)
        }
    }
}


extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

class SectionCustomHeader: UITableViewHeaderFooterView {
    let title = UILabel()
    let image = UIImageView()
    let sectionTitle = UIButton()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configureContents()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureContents() {
        image.translatesAutoresizingMaskIntoConstraints = false
        sectionTitle.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(image)
        contentView.addSubview(sectionTitle)
        contentView.heightAnchor.constraint(equalToConstant: 100)
        
        NSLayoutConstraint.activate([
            image.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            image.widthAnchor.constraint(equalToConstant: 100),
            image.heightAnchor.constraint(equalToConstant: 100),
            image.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            sectionTitle.heightAnchor.constraint(equalToConstant: 1000),
            sectionTitle.leadingAnchor.constraint(equalTo: image.trailingAnchor,
                   constant: 8),
            sectionTitle.trailingAnchor.constraint(equalTo:
                   contentView.layoutMarginsGuide.trailingAnchor),
            sectionTitle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
