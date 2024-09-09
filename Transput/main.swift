//
//  main.swift
//  Transput
//
//  Created by jin junjie on 2024/8/4.
//

import Foundation


import Cocoa
import os.log
let log = OSLog(subsystem: "com.janlely.inputmethod.Transput", category: "inputmethod")

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
