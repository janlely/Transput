//
//  RimeBridge.swift
//  Transput
//
//  Created by jin junjie on 2024/9/6.
//

import Foundation
import os.log


struct Schema {
    var schemaId: String
    var schemaName: String
}

class RimeBridge {
    private let rimeApi: RimeApi_stdbool = rime_get_api_stdbool().pointee
    private var committed: String = ""
    var cadidatesArray: [String] = [] //当前候选词列表
    var schemaList: [Schema]? = nil
    
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
        transputTraits.setCString("川普", to: \.distribution_name)
        transputTraits.setCString(distributionVersion, to: \.distribution_version)
        transputTraits.setCString("rime.transput", to: \.app_name)
        FileManager.default.changeCurrentDirectoryPath(sharedPath)
        rimeApi.initialize(nil)
        rimeApi.setup(&transputTraits)
        let _ = rimeApi.start_maintenance(true)
        rimeApi.join_maintenance_thread()
    }
    
    func createSession() -> RimeSessionId {
        return rimeApi.create_session()
    }
    
    func appendInput(_ session: RimeSessionId, keyCode: UInt16, char: Character, onCommit: (String) -> Void) -> String? {
        let rimeKeycode = MacOSKeycode.osxKeycodeToRime(keycode: keyCode, keychar: char,
                                                        shift: false,
                                                        caps: false)
        let result = rimeApi.process_key(session, Int32(rimeKeycode), 0)
        if !result {
            os_log(.info, log: log, "maybe not in typing mode, keyCode: %{public}d", keyCode)
            return nil
        }
        rimeUpdate(session, success: result)
//        if !hasUnCommitText(session) {
//            onCommit(committed)
//            committed = ""
//            return ""
//        }
//
//        var ctx = RimeContext_stdbool.rimeStructInit()
//        if rimeApi.get_context(session, &ctx) {
//            return committed + (ctx.composition.preedit.map({ String(cString: $0) }) ?? "")
//        }
//        
//        return nil
//        
        if let unCommitedText = unCommitText(session) {
            return committed + unCommitedText
        }
        
        os_log(.info, log: log, "has no uncommited text")
        onCommit(committed)
        committed = ""
        
        return ""
    }
    
    func makeCadidates(_ session: RimeSessionId) {
        var candidates = [String]()
        var ctx = RimeContext_stdbool.rimeStructInit()
        if rimeApi.get_context(session, &ctx) {
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
        rimeApi.clear_composition(session)
    }
    
    func unCommitText(_ session: RimeSessionId) -> String? {
        var ctx = RimeContext_stdbool.rimeStructInit()
        if rimeApi.get_context(session, &ctx) {
            let uncommitText = ctx.composition.preedit.map({ String(cString: $0) })
            return uncommitText
        }
        return nil
    }
    
    private func rimeConsumeCommittedText(_ session: RimeSessionId) {
        var commitText = RimeCommit.rimeStructInit()
        if rimeApi.get_commit(session, &commitText) {
            if let text = commitText.text {
                committed.append(contentsOf: String(cString: text))
            }
            _ = rimeApi.free_commit(&commitText)
        }
    }
    
    func selectCandidates(_ session: RimeSessionId, text: String) {
        guard let index = self.cadidatesArray.firstIndex(of: text) else {
            os_log(.error, log: log, "cannot find candidates in cadidatesArray")
            return
        }
        if rimeApi.select_candidate(session, index) {
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
        if rimeApi.get_context(session, &ctx) {
            return committed.count + Int(ctx.composition.cursor_pos)
        }
        os_log(.error, log: log, "error get composition.cursor_pos")
        return 0
    }
    
    func restart() {
        os_log(.info, log: log, "stopping rime")
        rimeApi.finalize()
        os_log(.info, log: log, "starting rime")
        setup()
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
    
    
    func getSchemaList() -> [Schema]? {
        os_log(.debug, log: log, "getSchemaList")
        if schemaList != nil {
            return schemaList
        }
        schemaList = []
        var list = RimeSchemaList()
        if rimeApi.get_schema_list(&list) {
            for item in UnsafeBufferPointer(start: list.list, count: list.size) {
                let name = String.init(validatingCString: item.name)
                let id = String.init(validatingCString: item.schema_id)
                if name == nil || id == nil {
                    continue
                }
                os_log(.debug, log: log, "schema name: \(name!), schema id: \(id!)")
                schemaList!.append(Schema(
                    schemaId: id!,
                    schemaName: name!
                ))
            }
        }
        return schemaList
    }
    
    func changeSchema(sid: RimeSessionId, schemaId: String) {
        os_log(.info, log: log, "going to change schema to: %@", schemaId)
        let _ = schemaId.withCString{cString in
            if rimeApi.select_schema(sid, cString) {
                os_log(.info, log: log, "changed schema to %@", schemaId)
                
            } else {
                os_log(.error, log: log, "error change schema to: %@", schemaId)
            }
            var status = RimeStatus_stdbool.rimeStructInit()
            if rimeApi.get_status(sid, &status) {
                os_log(.info, log: log, "current schema: %@", String.init(validatingCString: status.schema_name)!)
            }
        }
    }
}

