//
//  Constants.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 29/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

func env<T>(dev development: T, stg staging: T, prod production: T) -> T {
    var v: T!
    
    #if ENVIRONMENT_DEBUG
        v = development
    #elseif ENVIRONMENT_STAGING
        v = staging
    #else // Live
        v = production
    #endif
    
    return v
}

enum Constants {
    static let fontDmr = "Montserrat"
    static let prefix75 = "75"
    
    enum Services {
        static let langPays = "FR/fr"
        static let emailServiceFait = [""]
        
        static let apiBaseUrl = env(dev: "",
                                    stg: "",
                                    prod: "")
        static let apiUrl = "signalement/api"
        
        static let tokenWS = env(dev: "",
                                 stg: "",
                                 prod: "")
        
        static let headerKeyTokenWS = ""
        
        static let apiBaseUrlEquipement = env(dev: "",
                                              stg: "",
                                              prod: "")
        
        /
        static let authBaseUrl = env(dev: "",
                                     stg: "",
                                     prod: "")
        
        static let solenUrl = env(dev: "",
                                  stg: "",
                                  prod: "")
        
        static let authorization = env(
            dev: "",
            stg: "",
            prod: "")
        
        static let apiKeyGMS = env(dev: "",
                                   stg: "",
                                   prod: "")
        
        static let urlForgetPassword = ""
        static let urlRegiserCompteParisien = ""
        
        static let urlDisplayProfile = ""
        static let urlDeleteAccount = ""
        static let urlCGU = ""
        static let urlConfidentialité = ""
    }
    
    enum Authentification {
        static let clientID = ""
        static let authorizationEndpoint = URL(string: "")!
        static let tokenEndpoint = URL(string: "")!
        static let userInfoEndpoint = URL(string: "")!
        static let logoutEndpoint = ""
        static let RedirectURI = ""
        static let userDefault = ""
    }
    
    enum Maps {
        static let parisLatitude = 48.856614
        static let parisLongitude = 2.3522219
        static let zoomLevel: Float = 12.0
        static let zoomLevel_50m: Float = 17.0
    }
    
    enum Key {
        static let categorieVersion = "categorieVersion"
        static let categorieList = "categorieList"
        static let categorieItems = "categorieItems"
        static let categorieIdSelect = "categorieIdSelect"
        
        static let actualitesVersion = "actualitesVersion"
        static let actualitesList = "actualitesList"
        
        static let aidesVersion = "aidesVersion"
        static let aidesList = "aidesList"
        
        static let categorieEquipementVersion = "categorieEquipementVersion"
        static let categorieEquipementItems = "categorieEquipementItems"
        
        static let newAnomalie = "newAnomalie"
        static let anomalieBrouillonList = "anomalieBrouillonList"
        
        static let priorityList = "priorityList"
        static let priorityId = "priorityId_"
        
        static let deviceToken = "deviceToken"
        
        static let firstName = "firstName"
        static let lastName = "lastName"
        static let email = "email"
        static let password = "password"
        static let isAgent = "isAgent"
        static let uid = "uid"
        static let hasAlreadyBeenConnected = "hasAlreadyBeenConnected"
        
        // Constant equipement
        static let equipementVersion = "equipementVersion"
        static let typeEquipementList = "typeEquipementList"
        
        static let separatorAdresseCoordonate = "***"
    }
    
    enum NoticationKey {
        static let typeAnomalieChanged = "TypeAnomalieChanged"
        static let photo1Changed = "Photo1Changed"
        static let photo2Changed = "Photo2Changed"
        static let priorityChanged = "PriorityChanged"
        static let descriptiveChanged = "DescriptiveChanged"
        static let anomaliesChanged = "AnomaliesChanged"
        static let addressNotification = "addressNotification"
        
        static let pushNotification = "pushNotification"
    }
    
    enum Image {
        static let noImage = "no_image"
        static let createAnomalie = "create_anomalie"
        static let searchAnomalie = "search_anomalie"
        static let showAnomalies = "show_anomalies"
        static let createAnomalieSelected = "create_anomalie_selected"
        static let follow = "follow"
        static let followSelected = "follow_selected"
        static let followDisabled = "follow_disabled"
        static let unfollow = "unfollow"
        static let unfollowSelected = "unfollow_selected"
        static let congratulate = "felicite"
        static let congratulateSelected = "felicite_selected"
        static let congratulateDisabled = "felicite_disabled"
        static let iconGeolocation = "icon_geo_location"
        static let addAnomalie = "add_anomalie"
        static let pinRose = "pin_rose_ios"
        static let anoDoneOther = "ano_done_other"
        static let anoOther = "ano_other"
        static let pinNoir = "pin_noir_ios"
        static let iconCheckPink = "icon_check_pink"
        static let iconCheckGrey = "icon_check_grey"
        static let iconCamera = "icon_camera"
        static let iconExit = "icon_exit"
        static let iconBack = "icon_back"
        static let thumbsUp = "icon_thumbsUp"
        static let iconBackChevron = "icon_back_chevron"
        static let iconChevron = "icon_chevron"
        static let illustration1 = "Illustration1.png"
        static let illustration2 = "Illustration2.png"
        static let illustration3 = "Illustration3.png"
        static let mapMenuSelected = "map_menu_selected"
        static let profilMenuSelected = "profil_menu_selected"
        static let iconEdit = "icon_edit"
        static let iconMonCompte = "monCompte"
        static let ramen = "image_1000"
        static let favoriteUncheck = "favorite_uncheck"
        static let favoriteCheck = "favorite_check"
        static let favoritePlus = "favorite_plus"
        static let favorite = "favorite"
        
        static let maxWith: CGFloat = 800
        static let compressionQuality: CGFloat = 0.85
        static let draftPhoto1 = "photo1.jpg"
        static let draftPhoto2 = "photo2.jpg"
        
        // Equipement
        static let iconEspacePublic = "TypeEspacePublic"
    }
    
    enum AlertBoxTitle {
        static let adresseInvalide = "Adresse invalide"
        static let searchAnomaly = "Rechercher une anomalie"
        static let locationDisabled = "Localisation désactivée"
        static let parametres = "Paramètres"
        static let annuler = "Annuler"
        static let reglages = "Réglages"
        static let modificationPreferences = "Modification des préférences"
        static let erreur = "Erreur"
        static let attention = "Attention"
        static let non = "Non"
        static let oui = "Oui"
        static let ok = "OK"
        static let restezInforme = "Restez informé.e"
        static let valider = "Valider"
        static let reessayer = "Réessayer"
        static let grantPhoto = "\(Bundle.main.displayName) veut accéder à la caméra"
        static let adresseHorsParis = "Adresse hors Paris"
        static let publier = "Publier"
        static let complementAdresseFacultatif = "Complément d'adresse (facultatif)"
        static let complementAdresse = "Complément d'adresse"
        static let information = "Information"
        static let messageServiceFait = "Message service fait"
    }
    
    enum AlertBoxMessage {
        static let adresseInvalide = "Vous êtes actuellement géolocalisé en dehors de Paris. L’application DansMaRue permet de signaler des anomalies uniquement dans Paris."
        static let locationDisabled = "Pour utiliser le suivi, veuillez activer le GPS dans Paramètres > \nConfidentialité > Services de localisation."
        static let followMalfunction = "Vous suivez maintenant cette anomalie."
        static let unfollowMalfunction = "Vous ne suivez plus cette anomalie."
        static let congratulate = "Merci d'avoir transmis vos félicitations aux agents ! "
        static let modificationPreferences = "Pour modifier les préférences, utilisez le menu Réglages."
        static let erreur = "Erreur d'authentification. \nVeuillez corriger"
        static let authenticationOk = "Authentification réussie"
        static let attention = "Vous n’avez pas finalisé votre déclaration d’anomalie. \nSouhaitez-vous enregistrer un brouillon ?"
        static let noConnexion = "Vous n'avez aucune connexion."
        static let anomalieResolue = "Vous signalez cette anomalie comme résolue."
        static let erreurChargementTypes = "Suite à un problème réseau, les données nécessaires à la création de votre demande n'ont pas pu être récupérées.\n Merci de recommencer ultérieurement"
        static let errorSaveLabel = "\nNous rencontrons des difficultés à enregistrer cette anomalie. \n\nMerci d\'essayer ultérieurement.\n\n Un brouillon a été sauvegardé dans votre espace"
        static let grantPhoto = "Veuillez accorder l'autorisation d'utiliser la caméra pour pouvoir prendre des photos."
        static let solvedMalfunction = "Vous déclarez ce signalement comme résolu."
        static let optinAutorisation = "Autorisez vous l'application à transmettre vos données de localisation et votre identifiant de téléphone"
        static let majDisponible = "Une nouvelle version de l'application est disponible sur l'App Store. Souhaitez-vous l'installer ?"
        static let majObligatoire = "Une nouvelle version majeure de l'application est disponible sur le PlayStore. Il est impératif de la mettre à jour pour continuer à utiliser l'application. Merci de l'installer."
        static let numRueObligatoire = "Pour une meilleure prise en charge de l'anomalie, veuillez compléter l'adresse avec un numéro de rue"
        static let erreurChargementEquipement = "Suite à un problème réseau, les données nécessaires à la récupération des équipements n'ont pas pu etre chargées"
        static let adresseHorsParis = "Impossible d'ajouter une adresse hors Paris aux favoris"
        static let maintenance = "\nL'application DansMaRue est actuellement en maintenance.\n\nMerci d'essayer ultérieurement."
        static let searchAnomaly = "Renseigner ci-dessous le numéro exact de l’anomalie"
    }
    
    enum LabelMessage {
        static let addAnomaly = "Ajouter une autre anomalie"
        static let searchAnomaly = "Rechercher une anomalie par numéro d'identification"
        static let showAnomaly = "Voir les anomalies déjà signalées"
        static let preciserPosition = "Préciser la position de l'anomalie"
        static let otherAnomalieLabel = "Autres anomalies autour de moi"
        static let otherAnomalieEquipementLabel = "Autres anomalies dans l'équipement"
        static let noDraft = "Vous n'avez pas de brouillon"
        static let noNotSolved = "Vous n'avez pas encore signalé d'anomalie"
        static let noSolved = "Vous n'avez pas encore d'anomalie résolue"
        static let about = "À Propos"
        static let aboutText = "L'application DansMaRue PARIS est un service de la Ville de Paris qui fonctionne uniquement à Paris. Elle utilise certaines fonctionnalités de votre smartphone (GPS et connexion 3G/4G/5G) qui nécessitent une bonne connexion. Si vous rencontrez des difficultés techniques liées à l'usage de l'application, n'hésitez pas à nous en informer via l'adresse mail DansMaRue_App@paris.fr\n\nLes informations ne sont pas traitées de manière instantanée. Les situations présentant un caractère dangereux et nécessitant la mise en oeuvre de mesures de protection rapides doivent continuer à faire l'objet d'une déclaration auprès des services d'urgence."
        static let monProfil = "Mon profil"
        static let actualites = "Actualités"
        static let aide = "Aide et conseils d’utilisation"
        static let voirProfile = "Voir mon profil complet"
        static let suppressionCompteMonParis = "Supprimer mon compte \"MonParis\""
        static let mesAnomalies = "Mes anomalies"
        static let type = "Type (obligatoire)"
        static let typeBackButton = "Type"
        static let select = "Sélectionner"
        static let photo = "Photo (obligatoire)"
        static let ajouter = "Ajouter"
        static let optionnelDetailsTitle = "Précisions facultatives"
        static let requiredDetailsTitle = "Informations obligatoires"
        static let description = "Description"
        static let saisirDetail = "Saisir plus de détails en 250 caractères maximum"
        static let priority = "Priorité"
        static let anomalieSolved = "Cette anomalie a été clôturée"
        static let anomalieInProgress = "Cette anomalie est en cours de résolution"
        static let bienvenue = "BIENVENUE !"
        static let envoyerInfo = "ENVOYEZ VOS INFORMATIONS !"
        static let restezEnContact = "RESTEZ EN CONTACT !"
        static let textSlide1 = "DansMaRue vous permet de participer à l’amélioration de votre cadre de vie en échangeant des informations avec les services de la Ville de Paris."
        static let textSlide2 = "Bien choisir le bon sujet (graffiti, objet abandonné, défaut sur la route, stationnement gênant…) dans la nomenclature \n Bien préciser et vérifier l’adresse exacte de l’anomalie avec un numéro de rue \n Joindre une ou plusieurs photos bien cadrées sur l’anomalie \n Rajouter une description complémentaire utile et courtoise"
        static let textSlide3 = "Connectez-vous avec Mon Paris (votre compte personnel parisien sur Paris.fr) pour suivre la prise en charge de votre contribution et accéder aux fonctionnalités complémentaires. \n Supprimez régulièrement vos anomalies clôturées pour ne pas saturer la mémoire de votre smartphone et ralentir l’application"
        static let waitLabel = "Merci de patienter pendant la transmission des informations."
        static let typeFavoris = "Types favoris"
        static let adressesFavorites = "Adresses favorites"
        static let titreTypeAno = "Informations"
        
        // Label Equipement
        static let anomalieCountLabel = " anomalies signalées"
        static let anomalieCountOneLabel = " anomalie signalée"
        static let defaultTypeContributionLabel = "Anomalie sur l'espace public"
        static let typeContributionLabel = "Contribuer pour ..."
        static let equipementSearchNotFound = "L'adresse fournie ne correspond à aucun bâtiment public"

        // VoiceOver
        static let followAnomaly = "Suivre l'anomalie"
        static let unfollowAnomaly = "Ne plus suivre l'anomalie"
        static let congratulateAnomaly = "Féliciter les agents"
        static let deletePhoto = "Supprimer la photo"
        static let reduceBottomSheet = "Réduire la liste des anomalies"
        
        // Favoris
        static let addAdresseFavorite = "Ajouter %@ aux favoris"
        static let removeAdresseFavorite = "Supprimer %@ des favoris"
        
        // Favoris Type
        static let addTypeFavorite = "Ajouter %@ aux types favoris"
        static let removeTypeFavorite = "Supprimer %@ des types favoris"
    }
    
    enum TitleButton {
        static let deconnecter = "Se déconnecter"
        static let connecter = "Se connecter"
        static let publier = "Publier"
        static let connexion = "Connexion"
        static let prendrePhoto = "Prendre une photo"
        static let choisirAlbum = "Choisir dans l'album"
        static let feliciter = "Féliciter"
        static let monCompte = "Mon Paris"
        static let declarerCommeResolue = "Déclarer résolue"
        static let allow = "Autoriser"
        static let refuse = "Refuser"
        static let close = "Fermer"
    }
    
    enum PlaceHolder {
        static let saisirAdresse = "Où est située l'anomalie ?"
        static let password = "Mot de passe"
        static let mail = "Mail"
        static let email = "Email"
        static let searchType = "Chercher un type"
    }
    
    enum StoryBoard {
        static let compteParisien = "CompteParisien"
        static let addAnomaly = "AddAnomaly"
        static let detailAnomaly = "AnomalyDetail"
        static let map = "Map"
        static let profile = "Profile"
        static let thanks = "Thanks"
        static let popupPhoto = "PopupPhoto"
        static let priority = "Priority"
        static let typeAnomalie = "TypeAnomalie"
        static let description = "DescriptiveAnomaly"
        static let welcome = "Welcome"
        static let typeContribution = "TypeContribution"
        static let manageFavorites = "ManageFavorites"
        static let manageAddress = "ManageAddress"
        static let messageTypeAno = "MessageTypeAno"
    }
    
    enum ViewControllerIdentifier {
        static let compteParisien = "CompteParisien"
        static let addAnomaly = "AddAnomalyViewController"
        static let detailAnomaly = "AnomalyDetailViewController"
        static let bottomSheet = "BottomSheetViewController"
        static let map = "MapViewController"
        static let profileAbout = "ProfileAboutViewController"
        static let profileActualites = "ProfileActualitesViewController"
        static let profileAide = "ProfileAidesViewController"
        static let profileDetail = "ProfileDetailViewController"
        static let profile = "ProfileViewController"
        static let modifyAddress = "modifyAddress"
        static let thanks = "Thanks"
        static let mail = "Mail"
        static let popupPhoto = "popupPhoto"
        static let welcome = "WelcomeSliderViewController"
        static let typeContribution = "TypeContributionViewController"
        static let messageTypeAno = "MessageTypeAnoViewController"
    }

    enum TabBarTitle {
        static let carte = "Carte"
        static let monEspace = "Mon espace"
    }
    
    enum ProfilTableView {
        static let profil = 0
        static let anomalies = 1
        static let actualites = 2
        static let aides = 3
        static let preferences = 4
        static let cgu = 5
        static let confidentialite = 6
        static let aPropos = 7
    }
    
    enum AccessibilityHint {
        static let searchBarHint = "Saisissez l'adresse de l'anomalie, champ à autocomplétion activable à partir de la saisie du premier caractère"
        static let searchBarTypeHint = "Saisissez le type de l'anomalie, champ à autocomplétion activable à partir de la saisie de trois caractères"
    }
    
    enum AccessibilityLabel {
        static let favoriteAdressButton = "Vos adresses favorites"
        static let favoriteTypesButton = "Vos types favorites"
        static let backButton = "Retour"
        static let editAddress = "Modifier l'adresse"
        static let typeTitle = "Type"
    }
}
