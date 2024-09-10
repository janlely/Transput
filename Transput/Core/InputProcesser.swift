//
//  InputProcessor.swift
//  Transput
//
//  Created by jin junjie on 2024/8/31.
//

import Foundation
import os.log
import Cocoa

class InputProcesser {
    
    private var isTyping = false
    private var headAndTail: String = ""
    var breakPos: Int = 0
    var preedit: String = ""
    var cadidatesRange: [Int] = [] //候选词对应的编码长度
    var isEnMode: Bool = false
    private var wubiDict: TrieNode! //五笔词库
    private var isCommandMode: Bool = false
    var rimeBridge: RimeBridge!
    private var session: RimeSessionId = 0

    
    func initialize(rimeBridge: RimeBridge) {
        self.rimeBridge = rimeBridge
        if session == 0 {
            session = rimeBridge.createSession()
        }
    }
    
    func hasNoCandidates() -> Bool {
        return rimeBridge.cadidatesArray.isEmpty
    }
    
    func getCursorPos() -> Int {
        if preedit.isEmpty {
            return breakPos
        }
        return breakPos + rimeBridge.getCursorPos(session)
    }
    
    func isEmpty() -> Bool {
        return headAndTail.isEmpty && preedit.isEmpty
    }
    
    func getComposingText() -> String {
        if preedit.isEmpty {
            return headAndTail
        }
        var copy = headAndTail
        copy.insert(str: preedit, at: breakPos)
        return copy
    }
    
    
    func processInput(_ charType: CharType, keyCode: UInt16) -> ResultState {
        
        let im = isCommandMode
        defer {
            if im {
                isCommandMode.toggle()
            }
        }
        return doProcessInput(charType, keyCode: keyCode)
    }
    
    func accept(_ content: String) {
        headAndTail.insert(str: content, at: breakPos)
        breakPos += content.count
        preedit = ""
        isTyping = false
    }
    
    func sendToRime(keyCode: UInt16, char: Character) {
        if let result = rimeBridge.appendInput(session, keyCode: keyCode, char: char, onCommit: { ctt in
            accept(ctt)
        }) {
            preedit = result
        } else {
            os_log(.error, log: log, "error sendToRime, keyCode: %{public}d, char: %{public}s", keyCode, String(char))
            accept(String(char))
        }
    }


    func doProcessInput(_ charType: CharType, keyCode: UInt16) -> ResultState {
        switch charType {
        case .backspace:
            if isTyping {
                sendToRime(keyCode: keyCode, char: ".")
                return .typing
            }
            if headAndTail.isEmpty {
                return .ignore
            }
            if breakPos > 0 {
                let range = Range(NSMakeRange(breakPos - 1, 1), in: headAndTail)
                headAndTail = headAndTail.replacingCharacters(in: range!, with: "")
                breakPos -= 1
            }
            return .typing
        case .enter:
            if isTyping {
                sendToRime(keyCode: keyCode, char: ".")
                return .conditionalCommit
            }
            return headAndTail.isEmpty ? .ignore : .commit
        case .lower(let char):
            if isTyping {
                sendToRime(keyCode: keyCode, char: char)
                return preedit.isEmpty ? .conditionalCommit : .typing
            }
            if isCommandMode {
                os_log(.debug, log: log, "处理命令")
                return handlerCommand(char, keyCode: keyCode)
            }
            return doProcessInput(.lower2(char: char), keyCode: keyCode)
        case .lower2(let char):
            if !isEnMode {
                isTyping = true
                sendToRime(keyCode: keyCode, char: char)
                return .typing
            }
            accept(String(char))
            return .typing
        case .number(let char):
            if isTyping {
                sendToRime(keyCode: keyCode, char: char)
                return isTyping ? .typing : .conditionalCommit
            }
            accept(String(char))
            return .conditionalCommit
        case .space:
            if isTyping {
                sendToRime(keyCode: keyCode, char: " ")
                return isTyping ? .typing : .conditionalCommit
            }
            accept(" ")
            return .conditionalCommit
        case .other(let char):
            if isTyping {
                sendToRime(keyCode: keyCode, char: char)
                return isTyping ? .typing : .conditionalCommit
            }
            accept(String(convertPunctuation(char)))
            return char == "/" ? .typing : .conditionalCommit
        case .left:
            if isTyping {
                sendToRime(keyCode: keyCode, char: ".")
                return .typing
            }
            if breakPos > 0 {
                breakPos -= 1
            }
            return .typing
        case .right:
            if isTyping {
                sendToRime(keyCode: keyCode, char: ".")
                return .typing
            }
            if breakPos < headAndTail.count {
                breakPos += 1
            }
            return .typing
        case .home:
            if isTyping {
                sendToRime(keyCode: keyCode, char: ".")
                return .typing
            }
            breakPos = 0
            return .typing
        case .end:
            if isTyping {
                sendToRime(keyCode: keyCode, char: ".")
                return .typing
            }
            breakPos = headAndTail.count
            return .typing
        case .forwardslash:
            if isTyping {
                sendToRime(keyCode: keyCode, char: "/")
                return isTyping ? .typing : .conditionalCommit
            }
            isCommandMode.toggle()
            os_log(.debug, log: log, "命令状态: %{public}s", isCommandMode ? "Yes" : "No")
            return isCommandMode ? doProcessInput(.other(char: "/"), keyCode: keyCode) : .typing
        }
    }
    
    func handlerCommand(_ char: Character, keyCode: UInt16) -> ResultState {
        switch char {
        case "v":
            os_log(.debug, log: log, "粘贴命令")
            if let pasteContent = NSPasteboard.general
                .string(forType: .string)?.filter({ !$0.isNewline }).prefix(100), !pasteContent.isEmpty {
                let range = Range(NSMakeRange(breakPos - 1, 1), in: headAndTail)
                headAndTail = headAndTail.replacingCharacters(in: range!, with: pasteContent)
                breakPos += pasteContent.count - 1
            }
            return .conditionalCommit
        case "t":
            os_log(.debug, log: log, "翻译命令")
            let range = Range(NSMakeRange(breakPos - 1, 1), in: headAndTail)
            headAndTail = headAndTail.replacingCharacters(in: range!, with: "")
            breakPos -= 1
            return .translate
        case "g":
            os_log(.debug, log: log, "提交命令")
            let range = Range(NSMakeRange(breakPos - 1, 1), in: headAndTail)
            headAndTail = headAndTail.replacingCharacters(in: range!, with: "")
            breakPos -= 1
            return headAndTail.isEmpty ? .typing : .commit
        case "s":
            os_log(.debug, log: log, "切换模式命令")
            if headAndTail != "/" {
                return doProcessInput(.lower2(char: "s"), keyCode: keyCode)
            }
            headAndTail = ""
            breakPos = 0
            return .toggleTranslate
        default:
            os_log(.debug, log: log, "不是命令")
            return doProcessInput(.lower2(char: char), keyCode: keyCode)
        }
    }

    
    func makeCadidates() -> [String] {
        if isEnMode {
            os_log(.info, log: log, "isEnMode,返回空的候选词")
            return []
        }
        rimeBridge.makeCadidates(session)
        return rimeBridge.cadidatesArray
    }

    func clear() {
        headAndTail = ""
        breakPos = 0
//        isEnMode = false
        isCommandMode = false
        rimeBridge.clearComposition(session)
    }
    
    
    func select(_ value: String) {
        rimeBridge.selectCandidates(session, text: value)
        if !rimeBridge.hasUnCommitText(session) {
            isTyping = false
        }
    }
    
    func toggleEnMode() {
        isEnMode.toggle()
        headAndTail.insert(str: preedit, at: breakPos)
        breakPos += preedit.count
        preedit = ""
        rimeBridge.clearComposition(session)
    }
    
}

enum ResultState {
    case ignore
    case commit
    case conditionalCommit
    case typing
    case translate
    case toggleTranslate
}

enum CharType {
    case lower(char: Character) //小写字母
    case lower2(char: Character) //小写字母,不带命令的
    case number(num: Character) //数字
    case other(char: Character) //其他可见字符：标点，大写字母
    case space
    case backspace
    case enter
    case left
    case right
    case home
    case end
    case forwardslash
}


extension String {
    mutating func insert(char: Character, at index: Int) {
        let newIndex = self.index(self.startIndex, offsetBy: index)
        self.insert(char, at: newIndex)
    }
    
    mutating func insert(str: String, at index: Int) {
        let newIndex = self.index(self.startIndex, offsetBy: index)
        self.insert(contentsOf: str, at: newIndex)
    }

    subscript(safe range: Range<String.Index>) -> Substring? {
        guard !range.isEmpty,
              range.lowerBound >= startIndex,
              range.upperBound <= endIndex,
              indices.contains(range.lowerBound)
        else { return nil }
        
        return self[range]
    }
}

extension Collection {

    /// Returns the element at the specified index if it exists, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
