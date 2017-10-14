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

    @IBOutlet weak var inPatientConversationButton: UIButton!
    @IBOutlet weak var videoConversationButton: UIButton!
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
        
        inPatientConversationButton.backgroundColor = UIColor(red: 0, green: 122.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        inPatientConversationButton.setTitleColor(UIColor(red: 1, green: 1, blue: 1, alpha: 1.0), for: .normal)
        
        videoConversationButton.backgroundColor = UIColor(red: 76.0/255.0, green: 217.0/255.0, blue: 100.0/255.0, alpha: 1.0)
        videoConversationButton.setTitleColor(UIColor(red:1, green: 1, blue: 1, alpha: 1.0), for: .normal)
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
