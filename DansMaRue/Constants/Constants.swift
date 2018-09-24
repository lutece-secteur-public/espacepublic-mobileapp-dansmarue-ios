//
//  Constants.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 29/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

func env<T>(dev development: T, stg staging: T, prod production:T) -> T {
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

struct Constants {
     
    
    static let fontDmr = "Montserrat"
    static let prefix75 = "75"
    
    struct Services {
        
        static let langPays = "FR/fr"
        static let emailServiceFait = ["@paris.fr", "@derichebourg.com"]
        
        static let apiBaseUrl = env(dev: "",
                                    stg: "",
                                    prod: "")
        static let apiUrl = "signalement/api"

        static let apiBaseUrlEquipement = env(dev: "",
                                    stg: "",
                                    prod: "")
        
        static let authBaseUrl = env(dev: "",
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
        
    }
    
    struct Maps {
        static let parisLatitude = 48.856614
        static let parisLongitude = 2.3522219
        static let zoomLevel: Float = 12.0
        static let zoomLevel_50m : Float = 17.0
    }
    
    struct Key {
        static let categorieVersion = "categorieVersion"
        static let categorieList = "categorieList"
        static let categorieItems = "categorieItems"
        static let categorieIdSelect = "categorieIdSelect"
        
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
        static let hasAlreadyBeenConnected = "hasAlreadyBeenConnected"
        
        // Constant equipement
        static let equipementVersion = "equipementVersion"
        static let typeEquipementList = "typeEquipementList"

    }
    
    struct NoticationKey {
        static let typeAnomalieChanged = "TypeAnomalieChanged"
        static let photo1Changed = "Photo1Changed"
        static let photo2Changed = "Photo2Changed"
        static let priorityChanged = "PriorityChanged"
        static let descriptiveChanged = "DescriptiveChanged"
        static let anomaliesChanged = "AnomaliesChanged"
        static let addressNotification = "addressNotification"
        
        static let pushNotification = "pushNotification"
    }
    
    struct Image {
        static let noImage = "no_image"
        static let createAnomalie = "create_anomalie"
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
        
        static let maxWith: CGFloat = 800
        static let compressionQuality: CGFloat = 0.85
        static let draftPhoto1 = "photo1.jpg"
        static let draftPhoto2 = "photo2.jpg"
        
        // Equipement
        static let iconEspacePublic = "TypeEspacePublic"
    }
    
    struct AlertBoxTitle {
        
        static let adresseInvalide = "Adresse invalide"
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
    }
    
    struct AlertBoxMessage {
        
        static let adresseInvalide = "Vous êtes actuellement géolocalisé en dehors de Paris. L’application DansMaRue permet de signaler des anomalies uniquement dans Paris."
        static let locationDisabled = "Pour utiliser le suivi, veuillez activer le GPS dans Paramètres > \nConfidentialité > Services de localisation."
        static let followMalfunction = "Vous suivez maintenant ce signalement."
        static let unfollowMalfunction = "Vous ne suivez plus ce signalement."
        static let congratulate = "Merci d'avoir transmis vos félicitations aux agents ! "
        static let modificationPreferences = "Pour modifier les préférences, utilisez le menu Réglages."
        static let erreur = "Erreur d'authentification. \nVeuillez corriger"
        static let authenticationOk = "Authentification réussie"
        static let attention = "Vous n’avez pas finalisé votre déclaration d’anomalie. \nSouhaitez-vous enregistrer un brouillon ?"
        static let noConnexion = "Vous n'avez aucune connexion."
        static let anomalieResolue = "Vous signalez cette anomalie comme résolue."
        static let erreurChargementTypes = "Suite à un problème réseau, les données nécessaires à la création de votre demande n'ont pas pu être récupérées.\n Merci de recommencer ultérieurement"
        static let errorSaveLabel = "Nous rencontrons des difficultés\nà enregistrer cette anomalie.\n\nMerci d\'essayer ultérieurement.\n\n Un brouillon a été sauvegardé dans votre espace"
        static let grantPhoto = "Veuillez accorder l'autorisation d'utiliser la caméra pour pouvoir prendre des photos."
        static let solvedMalfunction = "Vous déclarez ce signalement comme résolu."
        static let optinAutorisation = "Autorisez vous l'application à transmettre vos données de localisation et votre identifiant de téléphone"
    }
    
    struct LabelMessage {
        
        static let addAnomaly = "Ajouter une autre anomalie"
        static let preciserPosition = "Préciser la position de l'anomalie"
        static let otherAnomalieLabel = "Autres anomalies autour de moi"
        static let otherAnomalieEquipementLabel = "Autres anomalies dans l'équipement"
        static let noDraft = "Vous n'avez pas de brouillon"
        static let noNotSolved = "Vous n'avez pas encore signalé d'anomalie"
        static let noSolved = "Vous n'avez pas encore d'anomalie résolue"
        static let cgu = "CGU"
        static let cguText = "L'application DansMaRue Paris fonctionne uniquement à Paris. Elle utilise certaines fonctionnalités de votre smartphone  (GPS et connexion 3G/4G) qui nécessitent une bonne connexion. Si vous rencontrez des difficultés techniques liées à l'usage de l'application, n'hésitez pas à nous en informer via l'adresse mail DansMaRue_App@paris.fr\n\nLe dispositif DansMaRue (application mobile et formulaire web) a pour objectif de faciliter la communication entre les Parisien-nes, la Ville de Paris et ses partenaires et prestataires.\n\nLes informations transmises par les utilisateurs via le dispositif doivent être considérées comme des documents de travail qui aideront la Ville de Paris et ses partenaires et prestataires à organiser leur activité. Ils déterminent au cas par cas les actions à mettre en place.\n\nLa Ville de Paris et ses partenaires et prestataires s'engagent, dans un délai d'un mois, à prendre les mesures appropriées et à informer tout contributeur qui aura laissé ses coordonnées.\n\nLes informations ne sont pas traitées de manière instantanée. Les situations présentant un caractère dangereux et nécessitant la mise en œuvre de mesures de protection rapides doivent continuer à faire l'objet d'une déclaration auprès des services d'urgence."
        static let about = "À Propos"
        static let aboutText = "L'application DansMaRue PARIS est un service de la Ville de Paris qui fonctionne uniquement à Paris. Elle utilise certaines fonctionnalités de votre smartphone (GPS et connexion 3G/4G) qui nécessitent une bonne connexion. Si vous rencontrez des difficultés techniques liées à l'usage de l'application, n'hésitez pas à nous en informer via l'adresse mail DansMaRue_App@paris.fr\n\nLes informations ne sont pas traitées de manière instantanée. Les situations présentant un caractère dangereux et nécessitant la mise en oeuvre de mesures de protection rapides doivent continuer à faire l'objet d'une déclaration auprès des services d'urgence."
        static let voirProfile = "Voir mon profil complet"
        static let type = "Type"
        static let select = "Sélectionner"
        static let photo = "Photo (obligatoire)"
        static let ajouter = "Ajouter"
        static let description = "Description"
        static let saisirDetail = "Saisir plus de détails"
        static let priority = "Priorité"
        static let anomalieSolved = "Cette anomalie a été résolue"
        static let anomalieInProgress = "Cette anomalie est en cours de résolution"
        static let bienvenue = "BIENVENUE !"
        static let envoyerInfo = "ENVOYEZ VOS INFORMATIONS !"
        static let restezEnContact = "RESTEZ EN CONTACT !"
        static let textSlide1 = "DansMaRue vous permet de participer à l’amélioration de votre cadre de vie en échangeant des informations avec les services de la Ville de Paris."
        static let textSlide2 = "Un graffiti, un objet encombrant sur le trottoir, un défaut d’éclairage… Partagez vos informations en y associant une photo explicite."
        static let textSlide3 = "Connectez-vous avec MON COMPTE pour suivre la prise en charge de votre contribution et accéder aux fonctionnalités complémentaires."
        static let waitLabel = "Merci de patienter pendant la transmission des informations."
        
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
    }
    
    struct TitleButton {
        static let deconnecter = "Se déconnecter"
        static let connecter = "Se connecter"
        static let publier = "Publier"
        static let connexion = "Connexion"
        static let prendrePhoto = "Prendre une photo"
        static let choisirAlbum = "Choisir dans l'album"
        static let feliciter = "Féliciter"
        static let monCompte = "MON COMPTE"
        static let declarerCommeResolue = "Déclarer comme résolue"
        static let allow = "Autoriser"
        static let refuse = "Refuser"
    }
    
    struct PlaceHolder {
        static let saisirAdresse = "Où est située l'anomalie ?"
        static let password = "Mot de passe"
        static let mail = "Mail"
        static let email = "Email"
      
    }
    
    struct StoryBoard {
        
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
    }
    
    struct ViewControllerIdentifier {
        
        static let compteParisien = "CompteParisien"
        static let addAnomaly = "AddAnomalyViewController"
        static let detailAnomaly = "AnomalyDetailViewController"
        static let bottomSheet = "BottomSheetViewController"
        static let profileAbout = "ProfileAboutViewController"
        static let profileCgu = "ProfileCGUViewController"
        static let profileDetail = "ProfileDetailViewController"
        static let modifyAddress = "modifyAddress"
        static let thanks = "Thanks"
        static let mail = "Mail"
        static let popupPhoto = "popupPhoto"
        static let welcome = "WelcomeSliderViewController"
        static let typeContribution = "TypeContributionViewController"

    }
    struct TabBarTitle {
        static let carte = "Carte"
        static let monEspace = "Mon espace"
        
    }
    
}
