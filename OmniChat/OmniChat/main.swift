//
//  main.swift
//  OmniChat
//
//  Created by Brice Maltby on 6/10/17.
//  Copyright © 2017 Brice Maltby. All rights reserved.
//


import Foundation
import UIKit

UIApplicationMain(CommandLine.argc, UnsafeMutableRawPointer(CommandLine.unsafeArgv)
    .bindMemory(
        to: UnsafeMutablePointer<Int8>.self,
        capacity: Int(CommandLine.argc)), NSStringFromClass(CallHandler.self), NSStringFromClass(AppDelegate.self))




