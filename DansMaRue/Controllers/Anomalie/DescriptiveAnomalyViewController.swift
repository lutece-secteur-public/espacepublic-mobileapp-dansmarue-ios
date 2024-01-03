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
    let maxLength = 250
    var initialBottomConstraint: CGFloat?

    // MARK: - IBOutlets

    @IBOutlet var labelCounter: UILabel!
    @IBOutlet var textViewDescriptive: UITextView!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    weak var delegate: AddAnomalyViewController!
    @IBOutlet var titleDescriptionLabel: UILabel!

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        titleDescriptionLabel.adjustsFontForContentSizeCategory = true
        titleDescriptionLabel.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 12.0)
        titleDescriptionLabel.text = Constants.LabelMessage.saisirDetail
        titleDescriptionLabel.isHidden = true
        textViewDescriptive.adjustsFontForContentSizeCategory = true
        textViewDescriptive.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 14.0)
        textViewDescriptive.delegate = self
        textViewDescriptive.isAccessibilityElement = true
        textViewDescriptive.accessibilityTraits = .staticText
        textViewDescriptive.textColor = UIColor.greyDmr()
        // textViewDescriptive.accessibilityLabel = defaultDescriptive != nil && !defaultDescriptive!.isEmpty ? defaultDescriptive : Constants.LabelMessage.saisirDetail
        textViewDescriptive.text = defaultDescriptive != nil && !defaultDescriptive!.isEmpty ? defaultDescriptive : Constants.LabelMessage.saisirDetail

        let length = defaultDescriptive?.count ?? 0
        labelCounter.text = "\(length)/\(maxLength)"
        labelCounter.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 12.0)
        labelCounter.adjustsFontForContentSizeCategory = true
        labelCounter.textColor = UIColor.greyDmr()
        // Modification de la navigation bar
        navigationItem.title = Constants.LabelMessage.description
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(backAction))
        navigationItem.leftBarButtonItem?.accessibilityLabel = Constants.AccessibilityLabel.backButton
        if let image = UIImage(named: Constants.Image.iconBack) {
            navigationItem.leftBarButtonItem?.image = image
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "OK", style: .plain, target: self, action: #selector(saveAction))

        NotificationCenter.default.addObserver(self, selector: #selector(DescriptiveAnomalyViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(DescriptiveAnomalyViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Déploie automatiquement le clavier quand on arrive sur l'écran
        textViewDescriptive.becomeFirstResponder()
        // UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: textViewDescriptive)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        initialBottomConstraint = bottomConstraint.constant
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // Permet d'ajuster la taille du champs texte par rapport au clavier quand il apparait
    func adjustingHeight(show: Bool, notification: NSNotification) {
        // 1
        let userInfo = notification.userInfo!
        // 2
        let keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        // 3
        let animationDurarion = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        // 4
        var changeInHeight = (keyboardFrame.height)
        if !UIDevice.current.orientation.isLandscape {
            changeInHeight += 70
        }
        // 5
        UIView.animate(withDuration: animationDurarion, animations: { () in
            self.bottomConstraint.constant = show ? changeInHeight : self.initialBottomConstraint!
        })
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        adjustingHeight(show: true, notification: notification)
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        adjustingHeight(show: false, notification: notification)
    }

    // MARK: - Other methods

    @objc func backAction() {
        _ = navigationController?.popViewController(animated: true)
    }

    @objc func saveAction() {
        delegate.changeDescriptive(descriptive: textViewDescriptive.text)
        _ = navigationController?.popViewController(animated: true)
    }
}

// MARK: - Extension UITextViewDelegate

extension DescriptiveAnomalyViewController: UITextViewDelegate {
    // Vérifie si longueur max atteint
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let text = textViewDescriptive.text else { return true }
        let newLength = text.utf16.count - range.length
        return newLength < maxLength
    }

    // Compteur de caractères
    func textViewDidChange(_ textView: UITextView) {
        var counter = textViewDescriptive.text?.count ?? 0

        if counter > maxLength {
            textViewDescriptive.text = (textViewDescriptive.text as NSString).substring(to: maxLength)
            counter = textViewDescriptive.text?.count ?? 0
            DispatchQueue.main.async {
                UIAccessibility.post(notification: .announcement, argument: "Limite de caractères atteinte.")
            }
        }
        textViewDescriptive.accessibilityLabel = textView.text
        labelCounter.text = "\(counter)/\(maxLength)"
        labelCounter.textColor = UIColor.greyDmr()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.greyDmr() {
            if defaultDescriptive == nil || defaultDescriptive!.isEmpty {
                textView.text = nil
            } else {
                if let selectedRange = textView.selectedTextRange {
                    let newPosition = textView.endOfDocument
                    DispatchQueue.main.async {
                        textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                    }
                }
            }
            textView.textColor = UIColor.black
        }
        UIView.animate(withDuration: 0.25, animations: { () in
            self.titleDescriptionLabel.isHidden = false
        })
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            UIView.animate(withDuration: 0.25, animations: { () in
                self.titleDescriptionLabel.isHidden = true
            })
        }
    }
}
