//
//  ConfigWindowController.swift
//  Transput
//
//  Created by jin junjie on 2024/8/3.
//

import Foundation
import Cocoa
import os.log

class ConfigWindowController: NSWindowController {
    
    private var toggled: Bool = false
    @IBOutlet weak var apiKey: NSTextField!
    
    @IBOutlet weak var model: NSPopUpButton!
    
    @IBAction func toggled(_ sender: NSSwitch) {
        os_log(.info, log: log, "toggled")
        self.toggled.toggle()
    }
    
    @IBAction func save(_ sender: NSButton) {
        let apiKey = apiKey.stringValue
        os_log(.info, log: log, "model: %{public}s, apiKey: %{public}s", model.selectedItem!.title, apiKey)
        ConfigModel.shared.apiKey = apiKey
        ConfigModel.shared.useAITrans = toggled
        ConfigModel.shared.modelType = switch model.selectedItem!.title {
        case "通义千问": .tongyi
        case "GPT-3.5-turbo": .gpt3_5_turbo
        default: nil
        }
        sender.window?.orderOut(nil)
    }
    
    
    @IBAction func cancel(_ sender: NSButton) {
        os_log(.info, log: log, "cancel buttion clicked")
        sender.window?.orderOut(nil)
    }
    
}

extension NSTextField {
    open override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags: UInt = event.modifierFlags.rawValue
        let cmd = NSEvent.ModifierFlags.command.rawValue
        if (flags & cmd) == cmd  {
            // The command key is the ONLY modifier key being pressed.
            switch event.charactersIgnoringModifiers {
            case "x":
                return NSApp.sendAction(#selector(NSText.cut(_:)), to: window?.firstResponder, from: self)
            case "c":
                return NSApp.sendAction(#selector(NSText.copy(_:)), to: window?.firstResponder, from: self)
            case "v":
                return NSApp.sendAction(#selector(NSText.paste(_:)), to: window?.firstResponder, from: self)
            case "a":
                return NSApp.sendAction(#selector(NSText.selectAll(_:)), to: window?.firstResponder, from: self)
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}
