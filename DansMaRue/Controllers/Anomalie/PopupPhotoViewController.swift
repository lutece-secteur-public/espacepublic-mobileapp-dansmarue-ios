//
//  PopupPhotoViewController.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 01/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit
import AVFoundation

class PopupPhotoViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: AddAnomalyViewController!
    var isFirstPhoto = true
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var ajoutImageLabel: UILabel!
    @IBOutlet weak var btnPrisePhoto: UIButton_PrendrePhoto!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        self.buttonsView.layer.cornerRadius = 10
        self.buttonsView.layer.masksToBounds = true
        
        self.ajoutImageLabel.textColor = UIColor.greyDmr()
        
        
        btnPrisePhoto.isEnabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)
        
        self.showAnimate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBActions
    @IBAction func takePhoto(_ sender: UIButton_PrendrePhoto) {
        print(" prise de photo ...")
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            checkCameraStatus()
        } else {
            let alertController = UIAlertController(title: Constants.AlertBoxTitle.erreur, message: "Device has no camera", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default, handler: { (alert) in
                print("Device has no camera")
            })
            alertController.addAction(defaultAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func searchPhoto(_ sender: UIButton_RechercherPhoto) {
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = false
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func close(_ sender: UIButton_AnnulerPhoto) {
        self.removeAnimate()
    }
    
    //MARK: Other functions
    func showAnimate()
    {
        self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        });
    }
    
    func removeAnimate()
    {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.view.alpha = 0.0;
        }, completion:{(finished : Bool)  in
            if (finished)
            {
                self.view.removeFromSuperview()
            }
        });
    }

    /// Methode permettant de verifier les authorisations sur l'utilisation de la caméra
    ///
    func checkCameraStatus() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.video)))
        switch authStatus {
            case .authorized: showCameraPicker()
            case .denied: alertPromptToAllowCameraAccessViaSettings()
            case .notDetermined: permissionPrimeCameraAccess()
            default: permissionPrimeCameraAccess()
        }
    }
    
    /// Affiche une alerte pour demander la modification des authorisations pour l'utilisation de la caméra
    ///
    func alertPromptToAllowCameraAccessViaSettings() {
        let alert = UIAlertController(title: Constants.AlertBoxTitle.grantPhoto, message: Constants.AlertBoxMessage.grantPhoto, preferredStyle: .alert )
        alert.addAction(UIAlertAction(title: Constants.AlertBoxTitle.parametres, style: .cancel) { alert in
            UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
        })
        let cancelAction = UIAlertAction(title: Constants.AlertBoxTitle.annuler, style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }
    
    /// Permet de demander l'authorisation d'utiliser la camera pour la prise de photo
    ///
    func permissionPrimeCameraAccess() {
        if AVCaptureDevice.devices(for: AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.video))).count > 0 {
            AVCaptureDevice.requestAccess(for: AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.video)), completionHandler: { [weak self] granted in
                DispatchQueue.main.async {
                    self?.checkCameraStatus() // try again
                }
            })
        }
        
    }
    
    /// Ouverture de l'appareil photo
    ///
    func showCameraPicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = UIImagePickerController.SourceType.camera;
        imagePickerController.allowsEditing = false
        present(imagePickerController, animated: true, completion: nil)
    }
}


// MARK: Extensions
extension PopupPhotoViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the picker if the user canceled.
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        // The info dictionary may contain multiple representations of the image. You want to use the original.
        if let selectedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            // Dismiss the picker.
            dismiss(animated: true, completion: nil)
            self.removeAnimate()
            
            // Compress and resize Image
            let imageResize = selectedImage.resizeWithWidth(width: Constants.Image.maxWith)
            let compressData = imageResize!.jpegData(compressionQuality: Constants.Image.compressionQuality)
            let compressedImage = UIImage(data: compressData!)
            
            delegate.changePhoto(newPhoto: compressedImage!, isFirstPhoto: self.isFirstPhoto)
        } else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
    }
}

extension PopupPhotoViewController: UINavigationControllerDelegate {
    
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVMediaType(_ input: AVMediaType) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
