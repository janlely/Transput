//
//  AppDelegate.swift
//  AppDelegate
//
//  Created by jin junjie on 2024/7/25.
//

import Cocoa
import InputMethodKit
import os.log


class AppDelegate: NSObject, NSApplicationDelegate {
    var server = IMKServer()
//    var cfgPanel: SettingsPanel!
    var candidatesWindow: IMKCandidates!
    var rimeBridge: RimeBridge!
    func applicationWillFinishLaunching(_ notification: Notification) {
        self.server = IMKServer(name: Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String, bundleIdentifier: Bundle.main.bundleIdentifier)
        self.candidatesWindow = IMKCandidates(server: server, panelType: kIMKSingleRowSteppingCandidatePanel)
//        if cfgPanel == nil {
//            cfgPanel =  SettingsPanel()
//        }
        
        if rimeBridge == nil {
            os_log(.info, log: log, "initializing rimeBridge")
            rimeBridge = RimeBridge()
            rimeBridge.setup()
            os_log(.info, log: log, "rimeBridge initialized")
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {

    }
    
    func applicationWillTerminate(_ notification: Notification) {
    }
    
    func deploy() {
        os_log(.info, log: log, "start deploying")
        rimeBridge.restart()
        os_log(.info, log: log, "deploy finished")
    }

}


extension NSApplication {
  var appDelegate: AppDelegate{
    self.delegate as! AppDelegate
  }
}
