//
//  SignUpViewController.swift
//  OmniChat
//
//  Created by Brice Maltby on 6/2/17.
//  Copyright © 2017 Brice Maltby. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var phoneNumberField: UITextField!
    @IBOutlet weak var languagePicker: UIPickerView!
    
    let ref = Database.database().reference()
    
    
    let errorMessage = UIAlertController(title: "Error", message: "Please make sure email and password fields have been completed", preferredStyle: UIAlertControllerStyle.alert)
    
    @IBAction func createButtonAction(_ sender: Any) {
        createUser()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorMessage.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(SignUpViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createUser() {
        Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { (user, err) in
            if user != nil {
                
                let userRef = self.ref.child("users").child(user!.uid)
                userRef.child("email").setValue(self.emailField.text)
                userRef.child("phoneNumber").setValue(self.phoneNumberField.text)
                self.ref.child("data").child("phoneNumbers").child(self.phoneNumberField.text!).setValue(user?.uid)
                self.performSegue(withIdentifier: "signUpToHome", sender: self)
            }
            else {
                self.present(self.errorMessage, animated: true, completion: nil)
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 5
    }
    
    func dismissKeyboard() {
        if (self.emailField.isFirstResponder) {
            self.emailField.resignFirstResponder()
        } else if (self.passwordField.isFirstResponder) {
            self.passwordField.resignFirstResponder()
        } else if (self.phoneNumberField.isFirstResponder) {
            self.phoneNumberField.resignFirstResponder()
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
