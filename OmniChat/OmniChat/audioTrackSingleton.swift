//
//  audioTrackSingleton.swift
//  OmniChat
//
//  Created by Brice Maltby on 7/15/17.
//  Copyright © 2017 Brice Maltby. All rights reserved.
//

import UIKit

class audioTrackSingleton: NSObject {
    static let sharedInstance = audioTrackSingleton()
    
    var callerOrReceiver: String = "none"
}
