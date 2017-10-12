//
//  OriginalViewController.swift
//  OmniChat
//
//  Created by Brice Maltby on 10/12/17.
//  Copyright © 2017 Brice Maltby. All rights reserved.
//

import UIKit
import FirebaseAuth

class OriginalViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("view did load")
        
        Auth.auth().addStateDidChangeListener { (Auth, user) in
            if user == nil {
                self.performSegue(withIdentifier: "originalToSignUpView", sender: self)
            } else {
                print("user signed in")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
