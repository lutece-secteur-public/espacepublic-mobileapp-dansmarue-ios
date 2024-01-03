//
//  CustomUIAlertController.swift
//  DansMaRue
//
//  Created by alaeddine.oueslati on 22/09/2023.
//  Copyright © 2023 VilleDeParis. All rights reserved.
//

import UIKit

class CustomUIAlertController: UIViewController {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var inputTextField: FloatingLabelInput!
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var alertView: UIView!

    private var titleText: String?
    private var messageText: String?
    private var placeHolderText: String?

    var delegate: CustomAlertViewDelegate?
    let alertViewGrayColor = UIColor(red: 224.0/255.0, green: 224.0/255.0, blue: 224.0/255.0, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        // inputTextField.becomeFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAlertView()
        setupView()
        animateView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.setNeedsLayout()
        // view.layoutIfNeeded()
        /* cancelButton.addBorder(side: .Top, color: alertViewGrayColor, width: 1)
         cancelButton.addBorder(side: .Right, color: alertViewGrayColor, width: 1)
         searchButton.addBorder(side: .Top, color: alertViewGrayColor, width: 1) */
    }

    @IBAction func onTapSearchButton(_ sender: Any) {
        inputTextField.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        delegate?.okButtonTapped(textFieldValue: inputTextField.text!)
    }

    @IBAction func onTapCancelButton(_ sender: Any) {
        inputTextField.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        delegate?.cancelButtonTapped()
        dismissAlertView()
    }

    func configureText(title: String, message: String, placeHolder: String) {
        titleText = title
        messageText = message
        placeHolderText = placeHolder
    }

    private func updateAlertView() {
        titleLabel.text = titleText
        messageLabel.text = messageText
        inputTextField.placeholder = placeHolderText
    }

    private func setupView() {
        alertView.layer.cornerRadius = 15
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        titleLabel.isAccessibilityElement = true
        messageLabel.isAccessibilityElement = true
        inputTextField.isAccessibilityElement = true

        titleLabel.accessibilityTraits = .header
        messageLabel.accessibilityTraits = .staticText
        inputTextField.accessibilityTraits = .searchField

        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        messageLabel.numberOfLines = 0
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
    }

    private func applyDynamicType(label: UILabel, fontName: String, size: Float) {
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.scaledFont(name: fontName, textSize: CGFloat(size))
    }

    private func animateView() {
        alertView.alpha = 0
        alertView.frame.origin.y = alertView.frame.origin.y + 50
        UIView.animate(withDuration: 0.4, animations: { () in
            self.alertView.alpha = 1.0
            self.alertView.frame.origin.y = self.alertView.frame.origin.y - 50
        })
    }

    private func dismissAlertView() {
        view.removeFromSuperview()
    }
}

protocol CustomAlertViewDelegate: class {
    func okButtonTapped(textFieldValue: String)
    func cancelButtonTapped()
}
