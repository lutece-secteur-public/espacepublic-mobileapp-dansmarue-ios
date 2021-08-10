//
//  ProfileViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 16/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

    //MARK: - Properties
    var currentFilter = "Draft"
    var malfunctionDraftArray: [Anomalie] = []
    var malfunctionSolvedArray: [Anomalie] = []
    var malfunctionNotSolvedArray: [Anomalie] = []
    // Array [Drafts, Not Solved, Solved]
    let malfunctionSections = ["Brouillons", "En cours", "Clôturées"]
    var isPremierAffichageFormConnexion = true;
    
    var vSpinner : UIView?
    
    
    //MARK: - IBOutlets
    @IBOutlet weak var malfunctionTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var malfunctionTableView: UITableView!
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        malfunctionTableView.tableFooterView = UIView()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = UIColor.pinkDmr()
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue:UIColor.white])

    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationItem.title = ""
        if User.shared.isLogged {
            if let firstName = User.shared.firstName, let lastName = User.shared.lastName {
                self.navigationItem.title = "\(firstName) \(lastName)"
            }
        } else if(!isPremierAffichageFormConnexion) {
            //affichage de la carte
            isPremierAffichageFormConnexion=true;
            self.tabBarController?.selectedIndex = 0
        } else {
            // Connexion de l'utilisateur
            isPremierAffichageFormConnexion=false
            let compteParisienVC = UIStoryboard(name: Constants.StoryBoard.compteParisien, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.compteParisien)
            self.navigationController?.present(compteParisienVC, animated: true)
        }
        
        self.malfunctionDraftArray = [Anomalie] (AnomalieBrouillon.shared.anomalies.values)
        self.malfunctionDraftArray.sort(by: { $0.dateHour.compare($1.dateHour) == .orderedDescending })

        // Chargement de la liste des anomalies 
        self.malfunctionSolvedArray.removeAll()
        self.malfunctionNotSolvedArray.removeAll()
        
        switch currentFilter
        {
        case "Not Solved":
            fillMalfunctionNotSolvedArray()
        case "Solved":
           fillMalfunctionSolvedArray()
        default:
            break
        }
        
        self.malfunctionTableView.reloadData()
    }

    //MARK: - IBActions
    @IBAction func changeMalfunctionFilter(_ sender: Any) {
        switch malfunctionTypeSegmentedControl.selectedSegmentIndex
        {
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
        self.malfunctionSolvedArray.removeAll()
            if User.shared.isLogged, let uid = User.shared.uid {
            DispatchQueue.global().async {
                //Affichage du spinner de chargement
                self.showSpinner(onView: self.view)
                
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
                            //Fin du chargement
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
        
        self.malfunctionNotSolvedArray.removeAll()
        if User.shared.isLogged, let uid = User.shared.uid {
            DispatchQueue.global().async {
                //Affichage du spinner de chargement
                self.showSpinner(onView: self.view)
                
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
                            //Fin du chargement
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
    
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
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
            //Si ano DMR, on affiche le détail
            if source == AnomalieSource.dmr {
                DispatchQueue.global().async {
                    
                    RestApiManager.sharedInstance.getIncidentById(idSignalement: anomalie.id, source: source){ (anomalie: Anomalie) in
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
        
        switch malfunctionTypeSegmentedControl.selectedSegmentIndex
        {
        case 0:
            filterSelected = malfunctionDraftArray[indexPath.row].anomalieStatus
        case 1:
            filterSelected = malfunctionNotSolvedArray[indexPath.row].anomalieStatus
        case 2:
            filterSelected = malfunctionSolvedArray[indexPath.row].anomalieStatus
        default:
            filterSelected = .Brouillon
            break
        }
        
        switch filterSelected
        {
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
            self.navigationController?.pushViewController(addAnomalyViewController, animated: true)
        case .Ouvert, .ATraiter:
            getDetailsAnomalies(anomalie: malfunctionNotSolvedArray[indexPath.row], source: malfunctionNotSolvedArray[indexPath.row].source)
        case .Resolu:
            getDetailsAnomalies(anomalie: malfunctionSolvedArray[indexPath.row], source: malfunctionSolvedArray[indexPath.row].source)

        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            switch currentFilter
            {
            case "Draft":
                AnomalieBrouillon.shared.remove(anomalie: malfunctionDraftArray[indexPath.row])
                 malfunctionDraftArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            case "Not Solved":
                RestApiManager.sharedInstance.unfollow(anomalie: malfunctionNotSolvedArray[indexPath.row] ,onCompletion: { (result: Bool) in
                    if result {
                        //Mise à jour de l'UI
                        DispatchQueue.main.async {
                            self.malfunctionNotSolvedArray.remove(at: indexPath.row)
                            tableView.deleteRows(at: [indexPath], with: .fade)
                            
                        }
                    }
                })
                
            case "Solved":
                RestApiManager.sharedInstance.unfollow(anomalie: malfunctionSolvedArray[indexPath.row] ,onCompletion: { (result: Bool) in
                    if result {
                        //Mise à jour de l'UI
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

extension ProfileViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentFilter
        {
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
        
        switch currentFilter
        {
        case "Draft":
            if malfunctionDraftArray.count > 0 {
                numberOfSections = 1
                tableView.separatorStyle = .singleLine
                tableView.backgroundView = nil
            } else {
                numberOfSections = 1
                let noDataLabel: UILabel     = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
                noDataLabel.text          = Constants.LabelMessage.noDraft
                noDataLabel.textColor     = UIColor.greyDmr()
                noDataLabel.textAlignment = .center
                noDataLabel.lineBreakMode = .byWordWrapping
                noDataLabel.numberOfLines = 2
                tableView.backgroundView  = noDataLabel
                tableView.separatorStyle  = .none
            }
        case "Not Solved":
            if malfunctionNotSolvedArray.count > 0 {
                numberOfSections = 1
                tableView.separatorStyle = .singleLine
                tableView.backgroundView = nil
            } else {
                numberOfSections = 1
                let noDataLabel: UILabel     = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
                noDataLabel.text          = Constants.LabelMessage.noNotSolved
                noDataLabel.textColor     = UIColor.greyDmr()
                noDataLabel.textAlignment = .center
                noDataLabel.lineBreakMode = .byWordWrapping
                noDataLabel.numberOfLines = 2
                tableView.backgroundView  = noDataLabel
                tableView.separatorStyle  = .none
            }
        case "Solved":
            if malfunctionSolvedArray.count > 0 {
                numberOfSections = 1
                tableView.separatorStyle = .singleLine
                tableView.backgroundView = nil
            } else {
                numberOfSections = 1
                let noDataLabel: UILabel     = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
                noDataLabel.text          = Constants.LabelMessage.noSolved
                noDataLabel.textColor     = UIColor.greyDmr()
                noDataLabel.textAlignment = .center
                noDataLabel.lineBreakMode = .byWordWrapping
                noDataLabel.numberOfLines = 2
                tableView.backgroundView  = noDataLabel
                tableView.separatorStyle  = .none
            }
        default:
            numberOfSections = malfunctionSections.count
        }
        
        return numberOfSections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch currentFilter
        {
        case "All":
            return malfunctionSections[section]
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let malfunctionCell = tableView.dequeueReusableCell(withIdentifier: "malfunction_cell")
        
        switch currentFilter
        {
        case "Draft":
            displayAnomalie(atSection: 0, andRow: indexPath.row, malfunctionCell!)
        case "Not Solved":
            displayAnomalie(atSection: 1, andRow: indexPath.row, malfunctionCell!)
        case "Solved":
            displayAnomalie(atSection: 2, andRow: indexPath.row, malfunctionCell!)
        default:
            displayAnomalie(atSection: indexPath.section, andRow: indexPath.row, malfunctionCell!)
            break
        }
        
        return malfunctionCell!
        
    }
    
    //MARK: - Other functions
    func displayAnomalie(atSection section: Int, andRow row: Int, _ malfunctionCell: UITableViewCell)  {
        let malfunctionImage = malfunctionCell.viewWithTag(102) as! UIImageView
        let malfunctionMainTitle = malfunctionCell.viewWithTag(103) as! UILabel
        let malfunctionAddress = malfunctionCell.viewWithTag(104) as! UILabel
        let malfunctionSecondTitle = malfunctionCell.viewWithTag(105) as! UILabel
        let malfunctionTypeTitle = malfunctionCell.viewWithTag(106) as! UILabel

        var anomalie: Anomalie
        
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
        
        malfunctionTypeTitle.textColor = UIColor.orangeDmr()
    }

}

extension ProfileViewController: CustomNavigationDelegate {
    
    func displayAddAnomaly(anomalySelected: Anomalie) {
        let addAnomalyStoryboard = UIStoryboard(name: Constants.StoryBoard.addAnomaly, bundle: nil)
        let addAnomalyViewController = addAnomalyStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.addAnomaly) as! AddAnomalyViewController
        addAnomalyViewController.currentAnomalie = anomalySelected
        self.navigationController?.pushViewController(addAnomalyViewController, animated: true)
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
