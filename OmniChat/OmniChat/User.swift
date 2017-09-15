//
//  User.swift
//  OmniChat
//
//  Created by Brice Maltby on 6/10/17.
//  Copyright © 2017 Brice Maltby. All rights reserved.
//

import Foundation
import AVFoundation
import Firebase

struct User {
    
    static var sharedInstance = User()
    
    func status() -> String? {
        if Auth.auth().currentUser != nil {
            return (Auth.auth().currentUser?.uid)!
        } else {
            return nil
        }
    }
    
    /*
    func escapingStatus(handler:@escaping (_ userPhoneNumber:String?) ->Void ) {
        if Auth.auth().currentUser != nil {
            handler(Auth.auth().currentUser?.uid)
        } else {
            print("logoutUser")
        }
    }
    
    func userPhoneNumber() -> String {
        //let ref: DatabaseReference
        let uid = escapingStatus() { (number) -> Void in
            if let number = number {
                let phoneNumber = self.getNumber()
                return phoneNumber
            }
        }
    }
    
    func getNumber() -> String {
        let number = Database.database().reference().child("users").child(uid!).child("phoneNumber").observeSingleEvent(of: .value, with: { (snap) in
            let phoneNumber = snap.value
            return phoneNumber
        })
    }
    
    
    func currentUserUid(completion: (String) -> Void) {
        if  Auth.auth().currentUser != nil {
            return String((Auth.auth().currentUser?.uid)!)
        } else {
            print("logout user")
        }
    }
    
    
    func hardProcessingWithString(input: String, completion: (result: String) -> Void) {
        ...
            completion("we finished!")
    }
    
    hardProcessingWithString("commands") {
    (result: String) in
    print("got back: \(result)")
    }*/
}
