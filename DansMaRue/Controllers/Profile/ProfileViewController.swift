//
//  ProfileViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 16/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import SafariServices
import UIKit
import WebKit

class ProfileViewController: UIViewController {
    // MARK: - Properties

    var currentFilter = "Draft"
    var malfunctionDraftArray: [Anomalie] = []
    var malfunctionSolvedArray: [Anomalie] = []
    var malfunctionNotSolvedArray: [Anomalie] = []
    // Array [Drafts, Not Solved, Solved]
    let malfunctionSections = ["Brouillons", "En cours", "Clôturées"]
    var isPremierAffichageFormConnexion = true
    var anomalieByRow = [Int: Anomalie]()
    
    var vSpinner: UIView?
    
    // MARK: - IBOutlets

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var malfunctionTypeSegmentedControl: UISegmentedControl!
    @IBOutlet var malfunctionTableView: UITableView!
    @IBOutlet var subTitle: UILabel!
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        malfunctionTableView.delegate = self
        malfunctionTableView.dataSource = self
        malfunctionTableView.estimatedRowHeight = 126
        malfunctionTableView.rowHeight = UITableView.automaticDimension
        title = Constants.TabBarTitle.monEspace
        subTitle.text = Constants.LabelMessage.mesAnomalies
        subTitle.isAccessibilityElement = true
        subTitle.accessibilityLabel = Constants.LabelMessage.mesAnomalies
        subTitle.accessibilityTraits = .header
        subTitle.textColor = UIColor.greyDmr()
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.pinkDmr()], for: .selected)
        updateTitleLabel(index: 0)
        
        malfunctionTableView.tableFooterView = UIView()
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = UIColor.pinkDmr()
        navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white])
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        subTitle.adjustsFontForContentSizeCategory = true
        subTitle.font = UIFont.preferredFont(forTextStyle: .title2)

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.pinkButtonDmr()
            appearance.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white])!
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = self.navigationController?.navigationBar.standardAppearance
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        malfunctionTableView.layoutIfNeeded()
        malfunctionTableView.reloadData()
        malfunctionDraftArray = [Anomalie](AnomalieBrouillon.shared.anomalies.values)
        malfunctionDraftArray.sort(by: { $0.dateHour.compare($1.dateHour) == .orderedDescending })

        // Chargement de la liste des anomalies
        malfunctionSolvedArray.removeAll()
        malfunctionNotSolvedArray.removeAll()
        
        switch currentFilter {
        case "Not Solved":
            fillMalfunctionNotSolvedArray()
        case "Solved":
            fillMalfunctionSolvedArray()
        default:
            break
        }
        
        malfunctionTableView.reloadData()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigationItem.titleView)
    }

    // MARK: - IBActions

    @IBAction func changeMalfunctionFilter(_ sender: Any) {
        updateTitleLabel(index: malfunctionTypeSegmentedControl.selectedSegmentIndex)
        switch malfunctionTypeSegmentedControl.selectedSegmentIndex {
        case 0:
            currentFilter = "Draft"
        case 1:
            currentFilter = "Not Solved"
            fillMalfunctionNotSolvedArray()
        case 2:
            currentFilter = "Solved"
            fillMalfunctionSolvedArray()
        default:
            break
        }
        
        malfunctionTableView.reloadData()
    }
    
    func fillMalfunctionSolvedArray() {
        malfunctionSolvedArray.removeAll()
        if User.shared.isLogged, let uid = User.shared.uid {
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                // Affichage du spinner de chargement
                DispatchQueue.main.async {
                    self.showSpinner(onView: self.view)
                }
                
                // Récupération des anomalies outdoor
                RestApiManager.sharedInstance.getIncidentsByUser(guid: uid, isIncidentSolved: true) { (anomalies: [Anomalie]) in
                    
                    for anomalie in anomalies {
                        self.malfunctionSolvedArray.append(anomalie)
                    }
                    
                    // Récupération des anomalies indoor
                    RestApiManager.sharedInstance.getIncidentsEquipementByUser(guid: uid) { (anomalies: [AnomalieEquipement]) in

                        for anomalie in anomalies {
                            if anomalie.anomalieStatus == .Resolu {
                                self.malfunctionSolvedArray.append(anomalie)
                            } else {
                                self.malfunctionNotSolvedArray.append(anomalie)
                            }
                        }
                        // Tri des anomalies par date
                        self.malfunctionNotSolvedArray.sort(by: { $0.dateHour.compare($1.dateHour) == .orderedDescending })
                        self.malfunctionSolvedArray.sort(by: { $0.dateHour.compare($1.dateHour) == .orderedDescending })
                        
                        DispatchQueue.main.async {
                            // Fin du chargement
                            self.removeSpinner()
                            
                            self.malfunctionTableView.reloadData()
                            
                            // Suppression des Badge du push Notification
                            UIApplication.shared.applicationIconBadgeNumber = 0
                        }
                    }
                }
            }
        }
    }
    
    func fillMalfunctionNotSolvedArray() {
        malfunctionNotSolvedArray.removeAll()
        if User.shared.isLogged, let uid = User.shared.uid {
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }

                // Affichage du spinner de chargement
                DispatchQueue.main.async {
                    self.showSpinner(onView: self.view)
                }

                // Récupération des anomalies outdoor
                RestApiManager.sharedInstance.getIncidentsByUser(guid: uid, isIncidentSolved: false) { (anomalies: [Anomalie]) in
                    
                    for anomalie in anomalies {
                        self.malfunctionNotSolvedArray.append(anomalie)
                    }
                    
                    // Récupération des anomalies indoor
                    RestApiManager.sharedInstance.getIncidentsEquipementByUser(guid: uid) { (anomalies: [AnomalieEquipement]) in

                        for anomalie in anomalies {
                            if anomalie.anomalieStatus == .Resolu {
                                self.malfunctionSolvedArray.append(anomalie)
                            } else {
                                self.malfunctionNotSolvedArray.append(anomalie)
                            }
                        }
                        // Tri des anomalies par date
                        self.malfunctionNotSolvedArray.sort(by: { $0.dateHour.compare($1.dateHour) == .orderedDescending })
                        self.malfunctionSolvedArray.sort(by: { $0.dateHour.compare($1.dateHour) == .orderedDescending })
                        
                        DispatchQueue.main.async {
                            // Fin du chargement
                            self.removeSpinner()
                            
                            self.malfunctionTableView.reloadData()
                            
                            // Suppression des Badge du push Notification
                            UIApplication.shared.applicationIconBadgeNumber = 0
                        }
                    }
                }
            }
        }
    }
    
    func showSpinner(onView: UIView) {
        let spinnerView = UIView(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            self.vSpinner?.removeFromSuperview()
            self.vSpinner = nil
        }
    }
    
    private func updateTitleLabel(index: Int) {
        titleLabel.text = malfunctionSections[index]
        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityLabel = malfunctionSections[index]
        titleLabel.textColor = UIColor.greyDmr()
        titleLabel.accessibilityTraits = .header
    }
    
    private func update() {
        if #available(iOS 13.0, *) {
            malfunctionTypeSegmentedControl.selectedSegmentTintColor = UIColor.pinkDmr()
        } else {
            // Fallback on earlier versions
        }
    }
    
    private func applyDynamicType(label: UILabel, fontName: String, size: Float) {
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.scaledFont(name: fontName, textSize: CGFloat(size))
    }
}

extension ProfileViewController: UITableViewDelegate {
    func getDetailsAnomalies(anomalie: Anomalie, source: AnomalieSource) {
        if let anoEquipement = anomalie as? AnomalieEquipement {
            DispatchQueue.global().async {
                RestApiManager.sharedInstance.getIncidentEquipementById(idSignalement: anoEquipement.id) { (anomalie: AnomalieEquipement) in
                    DispatchQueue.main.async {
                        let anomalyDetailStoryboard = UIStoryboard(name: Constants.StoryBoard.detailAnomaly, bundle: nil)
                        let anomalyDetailViewController = anomalyDetailStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.detailAnomaly) as! AnomalyDetailViewController
                        anomalyDetailViewController.selectedAnomaly = anomalie
                        // Gestion du mode d'affichage de l'écran de détail en fonction du status de l'anomalie
                        anomalyDetailViewController.currentAnomalyState = (anomalie.anomalieStatus == .Resolu ? .solved : .notsolved)
                        self.present(anomalyDetailViewController, animated: true, completion: nil)
                        anomalyDetailViewController.customNavigationDelegate = self
                    }
                }
            }
        } else {
            // Si ano DMR, on affiche le détail
            if source == AnomalieSource.dmr {
                DispatchQueue.global().async {
                    RestApiManager.sharedInstance.getIncidentById(idSignalement: anomalie.id, source: source) { (anomalie: Anomalie) in
                        DispatchQueue.main.async {
                            let anomalyDetailStoryboard = UIStoryboard(name: Constants.StoryBoard.detailAnomaly, bundle: nil)
                            let anomalyDetailViewController = anomalyDetailStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.detailAnomaly) as! AnomalyDetailViewController
                            anomalyDetailViewController.selectedAnomaly = anomalie
                            // Gestion du mode d'affichage de l'écran de détail en fonction du status de l'anomalie
                            anomalyDetailViewController.currentAnomalyState = (anomalie.anomalieStatus == .Resolu ? .solved : .notsolved)
                            self.present(anomalyDetailViewController, animated: true, completion: nil)
                            anomalyDetailViewController.customNavigationDelegate = self
                        }
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var filterSelected: AnomalieStatus
        
        switch malfunctionTypeSegmentedControl.selectedSegmentIndex {
        case 0:
            filterSelected = malfunctionDraftArray[indexPath.row].anomalieStatus
        case 1:
            filterSelected = malfunctionNotSolvedArray[indexPath.row].anomalieStatus
        case 2:
            filterSelected = malfunctionSolvedArray[indexPath.row].anomalieStatus
        default:
            filterSelected = .Brouillon
        }
        
        switch filterSelected {
        case .Brouillon, .APublier:
            let addAnomalyStoryboard = UIStoryboard(name: Constants.StoryBoard.addAnomaly, bundle: nil)
            let addAnomalyViewController = addAnomalyStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.addAnomaly) as! AddAnomalyViewController
            
            if let selectedAnomalie = malfunctionDraftArray[indexPath.row] as? AnomalieEquipement {
                addAnomalyViewController.typeContribution = .indoor
                addAnomalyViewController.currentAnomalie = selectedAnomalie
                if let equipement = ReferalManager.shared.getEquipement(forId: selectedAnomalie.equipementId) {
                    addAnomalyViewController.selectedEquipement = equipement
                }
            } else {
                addAnomalyViewController.typeContribution = .outdoor
                addAnomalyViewController.currentAnomalie = malfunctionDraftArray[indexPath.row]
            }
            navigationController?.pushViewController(addAnomalyViewController, animated: true)
        case .Ouvert, .ATraiter:
            getDetailsAnomalies(anomalie: malfunctionNotSolvedArray[indexPath.row], source: malfunctionNotSolvedArray[indexPath.row].source)
        case .Resolu:
            getDetailsAnomalies(anomalie: malfunctionSolvedArray[indexPath.row], source: malfunctionSolvedArray[indexPath.row].source)

        default:
            break
        }
    }
    
    func showPopupMaintenance() {
        let alert = UIAlertController(title: Constants.AlertBoxTitle.information, message: Constants.AlertBoxMessage.maintenance, preferredStyle: UIAlertController.Style.alert)
        let okBtn = UIAlertAction(title: "Ok", style: .default, handler: { (_: UIAlertAction) in
        })
        alert.addAction(okBtn)
        self.present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            switch currentFilter {
            case "Draft":
                AnomalieBrouillon.shared.remove(anomalie: malfunctionDraftArray[indexPath.row])
                malfunctionDraftArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            case "Not Solved":
                RestApiManager.sharedInstance.unfollow(anomalie: malfunctionNotSolvedArray[indexPath.row], onCompletion: { (result: Bool) in
                    if result {
                        // Mise à jour de l'UI
                        DispatchQueue.main.async {
                            self.malfunctionNotSolvedArray.remove(at: indexPath.row)
                            tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    }
                    else {
                        self.showPopupMaintenance()
                    }
                })
                
            case "Solved":
                RestApiManager.sharedInstance.unfollow(anomalie: malfunctionSolvedArray[indexPath.row], onCompletion: { (result: Bool) in
                    if result {
                        // Mise à jour de l'UI
                        DispatchQueue.main.async {
                            self.malfunctionSolvedArray.remove(at: indexPath.row)
                            tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    }
                })
            default:
                break
            }
        }
    }
}

extension ProfileViewController: UITableViewDataSource, SFSafariViewControllerDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentFilter {
        case "Draft":
            return malfunctionDraftArray.count
        case "Not Solved":
            return malfunctionNotSolvedArray.count
        case "Solved":
            return malfunctionSolvedArray.count
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 1
        
        switch currentFilter {
        case "Draft":
            if malfunctionDraftArray.count > 0 {
                numberOfSections = 1
                tableView.separatorStyle = .singleLine
                tableView.backgroundView = nil
            } else {
                numberOfSections = 1
                let noDataLabel: UILabel = .init(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
                noDataLabel.text = Constants.LabelMessage.noDraft
                noDataLabel.textColor = UIColor.greyDmr()
                noDataLabel.textAlignment = .center
                noDataLabel.lineBreakMode = .byWordWrapping
                noDataLabel.numberOfLines = 2
                tableView.backgroundView = noDataLabel
                tableView.separatorStyle = .none
                noDataLabel.adjustsFontForContentSizeCategory = true
                noDataLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            }
        case "Not Solved":
            if malfunctionNotSolvedArray.count > 0 {
                numberOfSections = 1
                tableView.separatorStyle = .singleLine
                tableView.backgroundView = nil
            } else {
                numberOfSections = 1
                let noDataLabel: UILabel = .init(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
                noDataLabel.text = Constants.LabelMessage.noNotSolved
                noDataLabel.textColor = UIColor.greyDmr()
                noDataLabel.textAlignment = .center
                noDataLabel.lineBreakMode = .byWordWrapping
                noDataLabel.numberOfLines = 2
                tableView.backgroundView = noDataLabel
                tableView.separatorStyle = .none
                noDataLabel.adjustsFontForContentSizeCategory = true
                noDataLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            }
        case "Solved":
            if malfunctionSolvedArray.count > 0 {
                numberOfSections = 1
                tableView.separatorStyle = .singleLine
                tableView.backgroundView = nil
            } else {
                numberOfSections = 1
                let noDataLabel: UILabel = .init(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
                noDataLabel.text = Constants.LabelMessage.noSolved
                noDataLabel.textColor = UIColor.greyDmr()
                noDataLabel.textAlignment = .center
                noDataLabel.lineBreakMode = .byWordWrapping
                noDataLabel.numberOfLines = 2
                noDataLabel.adjustsFontForContentSizeCategory = true
                noDataLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
                tableView.backgroundView = noDataLabel
                tableView.separatorStyle = .none
            }
        default:
            numberOfSections = malfunctionSections.count
        }
        
        return numberOfSections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch currentFilter {
        case "All":
            return malfunctionSections[section]
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let malfunctionCell = tableView.dequeueReusableCell(withIdentifier: "malfunction_cell")
        malfunctionCell?.isAccessibilityElement = true
        malfunctionCell?.accessibilityTraits = .button
        switch currentFilter {
        case "Draft":
            displayAnomalie(atSection: 0, andRow: indexPath.row, malfunctionCell!)
        case "Not Solved":
            displayAnomalie(atSection: 1, andRow: indexPath.row, malfunctionCell!)
        case "Solved":
            displayAnomalie(atSection: 2, andRow: indexPath.row, malfunctionCell!)
        default:
            displayAnomalie(atSection: indexPath.section, andRow: indexPath.row, malfunctionCell!)
        }
        
        return malfunctionCell!
    }
    
    // MARK: - Other functions

    func displayAnomalie(atSection section: Int, andRow row: Int, _ malfunctionCell: UITableViewCell) {
        let malfunctionImage = malfunctionCell.viewWithTag(102) as! UIImageView
        let malfunctionMainTitle = malfunctionCell.viewWithTag(103) as! UILabel
        let malfunctionAddress = malfunctionCell.viewWithTag(104) as! UILabel
        let malfunctionSecondTitle = malfunctionCell.viewWithTag(105) as! UILabel
        let malfunctionTypeTitle = malfunctionCell.viewWithTag(106) as! UILabel
        let responsableQuartier = malfunctionCell.viewWithTag(107) as! AnomalieUIButton
       
        applyDynamicType(label: malfunctionTypeTitle, fontName: "Montserrat-Bold", size: 15.0)
        applyDynamicType(label: malfunctionMainTitle, fontName: "Montserrat-Regular", size: 14.0)
        applyDynamicType(label: malfunctionAddress, fontName: "Montserrat-Light", size: 12.0)
        applyDynamicType(label: malfunctionSecondTitle, fontName: "Montserrat-Light", size: 12.0)

        var anomalie: Anomalie
        responsableQuartier.isHidden = true
        responsableQuartier.addTarget(self, action: #selector(redirectToSolen(sender:)), for: .touchUpInside)
        responsableQuartier.setTitle("", for: .normal)
        if section == 0 {
            anomalie = malfunctionDraftArray[row]
            if let photo = anomalie.photo1 {
                malfunctionImage.image = photo
            } else {
                malfunctionImage.image = anomalie.imageCategorie
            }
        } else if section == 1 {
            anomalie = malfunctionNotSolvedArray[row]
            let imageURL = URL(string: anomalie.firstImageUrl) ?? URL(string: Constants.Image.noImage)
            let placeholder = anomalie.imageCategorie
            malfunctionImage.sd_setImage(with: imageURL, placeholderImage: placeholder, options: .allowInvalidSSLCertificates)
        } else {
            anomalie = malfunctionSolvedArray[row]
            let imageURL = URL(string: anomalie.firstImageUrl) ?? URL(string: Constants.Image.noImage)
            let placeholder = anomalie.imageCategorie
            malfunctionImage.sd_setImage(with: imageURL, placeholderImage: placeholder, options: .allowInvalidSSLCertificates)
            responsableQuartier.isHidden = false
            responsableQuartier.anomalie = anomalie
            anomalieByRow[row] = anomalie
        }
        
        malfunctionMainTitle.text = anomalie.alias
        malfunctionAddress.text = anomalie.address
        malfunctionSecondTitle.text = DateUtils.formatDateByLocal(dateString: anomalie.date) + " " + anomalie.hour + " " + anomalie.number
        
        if let anoEquipement = anomalie as? AnomalieEquipement {
            if let equipement = ReferalManager.shared.getEquipement(forId: anoEquipement.equipementId) {
                let typeEquipement = ReferalManager.shared.getTypeEquipement(forId: equipement.parentId)
                malfunctionTypeTitle.text = typeEquipement?.name
            }
        } else {
            malfunctionTypeTitle.text = Constants.LabelMessage.defaultTypeContributionLabel
        }
        malfunctionTypeTitle.textColor = UIColor(hexString: "#C60")
        malfunctionSecondTitle.textColor = UIColor.greyDmr()
    }
    
    @objc
    private func redirectToSolen(sender: AnomalieUIButton) {
        let anomalie = sender.anomalie
        let latitude = anomalie.latitude
        let longitude = anomalie.longitude
        
        let contentController = WKUserContentController()
        let scriptSource = ""
        let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(script)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        view.addSubview(webView)

        if #available(iOS 11.0, *) {
            let layoutGuide = view.safeAreaLayoutGuide
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
            webView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
            webView.topAnchor.constraint(equalTo: layoutGuide.topAnchor).isActive = true
            webView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor).isActive = true
        } else {
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }

        if let url = URL(string: "\(Constants.Services.solenUrl)" + "&id_dmr=" + anomalie.number + "&Y=" + String(latitude) + "&X=" + String(longitude))
        {
            webView.load(URLRequest(url: url))
        }
    }
}

extension ProfileViewController: CustomNavigationDelegate {
    func displayAddAnomaly(anomalySelected: Anomalie) {
        let addAnomalyStoryboard = UIStoryboard(name: Constants.StoryBoard.addAnomaly, bundle: nil)
        let addAnomalyViewController = addAnomalyStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.addAnomaly) as! AddAnomalyViewController
        addAnomalyViewController.currentAnomalie = anomalySelected
        navigationController?.pushViewController(addAnomalyViewController, animated: true)
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
