//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import SchibstedAccount
import UIKit

class PaswordlessFlowViewController: UIViewController {
    @IBOutlet var countryCodeField: UITextField!
    @IBOutlet var phoneNumberField: UITextField!
    @IBOutlet var authCodeField: UITextField!
    @IBOutlet var resendButton: UIButton!
    @IBOutlet var shouldPersistUserSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        authCodeField.isEnabled = false
        resendButton.isEnabled = false
    }

    @IBAction func sendSMS(_: UIButton) {
        guard let countryCode = self.countryCodeField.text,
            let number = self.phoneNumberField.text,
            let phoneNumber = PhoneNumber(countryCode: countryCode, number: number)
        else {
            return
        }

        UIApplication.identityManager.sendCode(to: Identifier(phoneNumber)) { [weak self] result in
            print(result)
            if case .success() = result {
                DispatchQueue.main.async {
                    self?.authCodeField.isEnabled = true
                    self?.authCodeField.becomeFirstResponder()
                    self?.resendButton.isEnabled = true
                }
            }
        }
    }

    @IBAction func resendSMS(_: AnyObject) {
        guard let countryCode = self.countryCodeField.text,
            let number = self.phoneNumberField.text,
            let phoneNumber = PhoneNumber(countryCode: countryCode, number: number)
        else {
            return
        }

        UIApplication.identityManager.resendCode(to: Identifier(phoneNumber)) { [weak self] result in
            print(result)
            if case .success() = result {
                DispatchQueue.main.async {
                    self?.authCodeField.isEnabled = true
                    self?.authCodeField.becomeFirstResponder()
                }
            }
        }
    }

    @IBAction func validateCode(_: UIButton) {
        guard let code = authCodeField.text, code != "" else {
            return
        }

        UIApplication.identityManager.validate(oneTimeCode: code, persistUser: shouldPersistUserSwitch.isOn) { result in
            switch result {
            case .success:
                print("Code validated!")
            case let .failure(error):
                print(error)
            }
        }
    }
}
