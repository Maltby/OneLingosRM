//
//  LoginViewController.swift
//  OmniChat
//
//  Created by Brice Maltby on 6/18/17.
//  Copyright © 2017 Brice Maltby. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var emailFeild: UITextField!
    @IBOutlet weak var passwordFeild: UITextField!
    @IBAction func loginAction(_ sender: Any) {
        Auth.auth().signIn(withEmail: emailFeild.text!, password: passwordFeild.text!) { (user, error) in
            if user != nil {
                self.performSegue(withIdentifier: "createAccountToHome", sender: self)
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(SignUpViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }

    func dismissKeyboard() {
        if (self.emailFeild.isFirstResponder) {
            self.emailFeild.resignFirstResponder()
        } else if (self.passwordFeild.isFirstResponder) {
            self.passwordFeild.resignFirstResponder()
        }
    }
}
