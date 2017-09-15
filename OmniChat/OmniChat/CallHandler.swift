//
//  CallHandler.swift
//  OmniChat
//
//  Created by Brice Maltby on 6/10/17.
//  Copyright © 2017 Brice Maltby. All rights reserved.
//

import Foundation
import Firebase
import UIKit

class CallHandler: UIApplication {
    
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        
        var uid = User.sharedInstance.status()
        var ref = Database.database().reference()
        
        //print(uid)
        
        /*
        ref.child("callAttempts").child(uid!).observe(.value) { (snap) in
            print(snap.value)
        }*/
        
    }
}
