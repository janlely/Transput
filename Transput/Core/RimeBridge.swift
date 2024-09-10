//
//  RimeBridge.swift
//  Transput
//
//  Created by jin junjie on 2024/9/6.
//

import Foundation
import os.log

class RimeBridge {
    private let rimeAPI: RimeApi_stdbool = rime_get_api_stdbool().pointee
    private var committed: String = ""
    var cadidatesArray: [String] = [] //当前候选词列表
    
    func setup() {
        let userDir = if let pwuid = getpwuid(getuid()) {
          URL(fileURLWithFileSystemRepresentation: pwuid.pointee.pw_dir, isDirectory: true, relativeTo: nil).appending(components: "Library", "Transput")
        } else {
          try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Transput", isDirectory: true)
        }
        os_log(.info, log: log, "userDir: %{public}s", userDir.path())
        createDirIfNotExist(path: userDir)
        let logDir = FileManager.default.temporaryDirectory.appending(component: "rime.transput", directoryHint: .isDirectory)
        os_log(.info, log: log, "logDir: %{public}s", logDir.path())
        createDirIfNotExist(path: logDir)

        let sharedPath = Bundle.main.sharedSupportPath!
        let distributionVersion = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
        os_log(.info, log: log, "sharedPath : %{public}s", sharedPath)
        os_log(.info, log: log, "distributionVersion : %{public}s", distributionVersion)

        var transputTraits = RimeTraits.rimeStructInit()
        transputTraits.setCString(sharedPath, to: \.shared_data_dir)
        transputTraits.setCString(userDir.path(), to: \.user_data_dir)
        transputTraits.setCString(logDir.path(), to: \.log_dir)
        transputTraits.setCString("Transput", to: \.distribution_code_name)
        transputTraits.setCString("译输", to: \.distribution_name)
        transputTraits.setCString(distributionVersion, to: \.distribution_version)
        transputTraits.setCString("rime.transput", to: \.app_name)
        rimeAPI.setup(&transputTraits)
    }

    func initialize() {
        os_log(.info, log: log, "initializing rime")
        rimeAPI.initialize(nil)
    }
    
    func createSession() -> RimeSessionId {
        return rimeAPI.create_session()
    }
    
    func appendInput(_ session: RimeSessionId, keyCode: UInt16, char: Character, onCommit: (String) -> Void) -> String? {
        let rimeKeycode = MacOSKeycode.osxKeycodeToRime(keycode: keyCode, keychar: char,
                                                        shift: false,
                                                        caps: false)
        let result = rimeAPI.process_key(session, Int32(rimeKeycode), 0)
        if !result {
            os_log(.info, log: log, "maybe not in typing mode, keyCode: %{public}d", keyCode)
            return nil
        }
        rimeUpdate(session, success: result)
        if !hasUnCommitText(session) {
            onCommit(committed)
            committed = ""
            return ""
        }

        var ctx = RimeContext_stdbool.rimeStructInit()
        if rimeAPI.get_context(session, &ctx) {
            return committed + (ctx.composition.preedit.map({ String(cString: $0) }) ?? "")
        }
        
        return nil
    }
    
    func makeCadidates(_ session: RimeSessionId) {
        var candidates = [String]()
        var ctx = RimeContext_stdbool.rimeStructInit()
        if rimeAPI.get_context(session, &ctx) {
            let numCandidates = Int(ctx.menu.num_candidates)
            for i in 0..<numCandidates {
                let candidate = ctx.menu.candidates[i]
                if let value = candidate.text.map({ String(cString: $0) }) {
                    candidates.append(value)
                }
            }
        }
        self.cadidatesArray = candidates
    }
    
    func clearComposition(_ session: RimeSessionId) {
        rimeAPI.clear_composition(session)
    }
    
    func hasUnCommitText(_ session: RimeSessionId) -> Bool {
        var ctx = RimeContext_stdbool.rimeStructInit()
        if rimeAPI.get_context(session, &ctx) {
            let uncommitText = ctx.composition.preedit.map({ String(cString: $0) }) ?? ""
            return !uncommitText.isEmpty
        }
        return false
    }
    
    private func rimeConsumeCommittedText(_ session: RimeSessionId) {
        var commitText = RimeCommit.rimeStructInit()
        if rimeAPI.get_commit(session, &commitText) {
            if let text = commitText.text {
                committed.append(contentsOf: String(cString: text))
            }
            _ = rimeAPI.free_commit(&commitText)
        }
    }
    
    func selectCandidates(_ session: RimeSessionId, text: String) {
        guard let index = self.cadidatesArray.firstIndex(of: text) else {
            os_log(.error, log: log, "cannot find candidates in cadidatesArray")
            return
        }
        if rimeAPI.select_candidate(session, index) {
            rimeUpdate(session)
            return
        }
        os_log(.error, log: log, "error call rimeAPI.select_candidate")
    }
    
    func rimeUpdate(_ session: RimeSessionId, success: Bool = true) {
        if success {
            rimeConsumeCommittedText(session)
        }
    }
    
    func getCursorPos(_ session: RimeSessionId) -> Int {
        var ctx = RimeContext_stdbool.rimeStructInit()
        if rimeAPI.get_context(session, &ctx) {
            return committed.count + Int(ctx.composition.cursor_pos)
        }
        os_log(.error, log: log, "error get composition.cursor_pos")
        return 0
    }
    
    func restart() {
        os_log(.info, log: log, "stopping rime")
        rimeAPI.finalize()
        os_log(.info, log: log, "starting rime")
        initialize()
    }
    
    func createDirIfNotExist(path: URL) {
      let fileManager = FileManager.default
      if !fileManager.fileExists(atPath: path.path()) {
        do {
          try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
        } catch {
          print("Error creating user data directory: \(path.path())")
        }
      }
    }
}

//class KeyCodes {
//    static let keyMap: [Character: UInt16] = [
//        "a" : 0x00,
//        "s" : 0x01,
//        "d" : 0x02,
//        "f" : 0x03,
//        "h" : 0x04,
//        "g" : 0x05,
//        "z" : 0x06,
//        "x" : 0x07,
//        "c" : 0x08,
//        "v" : 0x09,
//        "b" : 0x0B,
//        "q" : 0x0C,
//        "w" : 0x0D,
//        "e" : 0x0E,
//        "r" : 0x0F,
//        "y" : 0x10,
//        "t" : 0x11,
//        "o" : 0x1F,
//        "u" : 0x20,
//        "i" : 0x22,
//        "p" : 0x23,
//        "l" : 0x25,
//        "j" : 0x26,
//        "k" : 0x28,
//        "n" : 0x2D,
//        "m" : 0x2E,
//        "1" : 0x12,
//        "2" : 0x13,
//        "3" : 0x14,
//        "4" : 0x15,
//        "6" : 0x16,
//        "5" : 0x17,
//        "9" : 0x19,
//        "7" : 0x1A,
//        "8" : 0x1C,
//        "0" : 0x1D
//    ]
//}
