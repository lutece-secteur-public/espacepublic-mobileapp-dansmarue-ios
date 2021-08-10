//
//  DescriptiveAnomalyViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 04/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class DescriptiveAnomalyViewController: UIViewController {

    // MARK: - Attributs
    var defaultDescriptive: String?
    let maxLength = 155

    //MARK: - IBOutlets
    @IBOutlet var labelCounter: UILabel!
    @IBOutlet var textViewDescriptive: UITextView!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    weak var delegate: AddAnomalyViewController!


    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        textViewDescriptive.delegate = self
        textViewDescriptive.text = defaultDescriptive
        
        let length = defaultDescriptive?.count ?? 0
        labelCounter.text =  "\(length)/\(maxLength)"
        
        //Modification de la navigation bar
        self.navigationItem.title = Constants.LabelMessage.description
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(backAction))
        if let image = UIImage(named: Constants.Image.iconBack) {
            navigationItem.leftBarButtonItem?.image = image

        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "OK", style: .plain, target: self, action: #selector(saveAction))
  
        NotificationCenter.default.addObserver(self, selector: #selector(DescriptiveAnomalyViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(DescriptiveAnomalyViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Déploie automatiquement le clavier quand on arrive sur l'écran
        self.textViewDescriptive.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //Permet d'ajuster la taille du champs texte par rapport au clavier quand il apparait
    func adjustingHeight(show:Bool, notification:NSNotification) {
        // 1
        var userInfo = notification.userInfo!
        // 2
        let keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        // 3
        let animationDurarion = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        // 4
        let changeInHeight = (keyboardFrame.height)
        //5
        UIView.animate(withDuration: animationDurarion, animations: { () -> Void in
           self.bottomConstraint.constant = changeInHeight
        })
    }
    @objc func keyboardWillShow(notification:NSNotification) {
        adjustingHeight(show: true, notification: notification)
    }
    
    @objc func keyboardWillHide(notification:NSNotification) {
        adjustingHeight(show: false, notification: notification)
    }
    

    //MARK: - Other methods
    @objc func backAction(){
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc func saveAction() {
        delegate.changeDescriptive(descriptive: textViewDescriptive.text)
        _ = navigationController?.popViewController(animated: true)
    }
    
    
}


//MARK: - Extension UITextViewDelegate
extension DescriptiveAnomalyViewController: UITextViewDelegate {
    
    // Vérifie si longueur max atteint
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let text = textViewDescriptive.text else { return true }
        let newLength = text.utf16.count - range.length
        return newLength < maxLength
    }

    //Compteur de caractères
    func textViewDidChange(_ textView: UITextView) {
       var counter = textViewDescriptive.text?.count ?? 0
        
        if(counter > maxLength){
            textViewDescriptive.text = (textViewDescriptive.text as NSString).substring(to: maxLength)
            counter = textViewDescriptive.text?.count ?? 0
        }
        
        labelCounter.text = "\(counter)/\(maxLength)"
        labelCounter.textColor = UIColor.greyDmr()
    }

}







