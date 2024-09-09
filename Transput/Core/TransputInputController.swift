//
//  TransputInputController.swift
//  Transput
//
//  Created by jin junjie on 2024/7/25.
//

import Cocoa
import InputMethodKit
import os.log

@objc(TransputInputController)
class TransputInputController: IMKInputController {
    
    
    private var candidatesWindow: IMKCandidates
    private var transPanel: NSPanel!
    private var inputModePanel: NSPanel!
    private var inputModelabel: NSTextField!
    private var translateSwitchPanel: NSPanel!
    private var translateSwitchLabel: NSTextField!
    private var transBtn: NSButton!
    private var transProg: CustomProgress!
    private var transRect: (x: CGFloat, y: CGFloat, height: CGFloat) = (0, 0, 0)
    private var inputProcesser: InputProcesser!
    private var shiftIsDown: Bool = false
    private var shiftPushedAlone: Bool = false
    private var timer: Timer!
    private var step: Double = 10
    private var progress: Double = 0

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        os_log(.debug, log: log, "init")
        self.candidatesWindow = (NSApplication.shared.delegate as! AppDelegate).candidatesWindow
        super.init(server: server, delegate: delegate, client: inputClient)
        initTransPanel()
        initInputModePanel()
        initTranslateSwitchPanel()
        inputProcesser = InputProcesser()
        inputProcesser.initialize(rimeBridge: NSApp.appDelegate.rimeBridge)
    }
    
    func initTransPanel() {
        os_log(.debug, log: log, "初始化翻译面板")
        transPanel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 50, height: 26),
                            styleMask: [.nonactivatingPanel],
                            backing: .buffered,
                            defer: false)

        // 设置窗口级别
        transPanel.level = .popUpMenu
        // 设置窗口行为
        transPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        transPanel.isFloatingPanel = true
        // 确保panel不会成为key window
        transPanel.becomesKeyOnlyIfNeeded = true
        // 允许panel接收鼠标事件，但不成为key window
        transPanel.acceptsMouseMovedEvents = true
        // 设置内容视图
        transPanel.contentView?.wantsLayer = true
        transPanel.contentView?.layer?.cornerRadius = 5

        transPanel.contentView?.layer?.backgroundColor = NSColor.red.cgColor
        
        
        transProg = CustomProgress(frame: NSRect(x: 0, y: 0, width: 100, height: 26))
        transProg.maxValue = 100
        transProg.bgimg.layer?.backgroundColor = NSColor.white.cgColor
        transProg.leftimg.layer?.backgroundColor = NSColor.black.cgColor
        transProg.isHidden = true
        transPanel.contentView?.addSubview(transProg)
        
        transBtn = NSButton(title: "翻译成英语", target: self, action: #selector(buttonClicked))
        transBtn.isBordered = false
        transBtn.layer?.backgroundColor = NSColor.white.cgColor
        transPanel.contentView?.addSubview(transBtn)
        
        
        transBtn.translatesAutoresizingMaskIntoConstraints = false
        transProg.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            transBtn.topAnchor.constraint(equalTo: transPanel.contentView!.topAnchor),
            transBtn.leadingAnchor.constraint(equalTo: transPanel.contentView!.leadingAnchor),
            transBtn.trailingAnchor.constraint(equalTo: transPanel.contentView!.trailingAnchor),
            transBtn.bottomAnchor.constraint(equalTo: transPanel.contentView!.bottomAnchor)
        ])
    }
    
    func initTranslateSwitchPanel() {
        os_log(.debug, log: log, "初始化翻译开关切换面板")
        translateSwitchPanel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 58, height: 26),
                            styleMask: [.nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        
        translateSwitchLabel = NSTextField(frame: NSRect.zero)
        translateSwitchLabel.isEditable = false
        translateSwitchLabel.font = NSFont.systemFont(ofSize: 16)
        translateSwitchLabel.backgroundColor = NSColor.white
        translateSwitchLabel.textColor = NSColor.black

        translateSwitchPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        translateSwitchPanel.isFloatingPanel = true
        // 确保panel不会成为key window
        translateSwitchPanel.becomesKeyOnlyIfNeeded = true
        translateSwitchPanel.level = .popUpMenu
        translateSwitchPanel.contentView?.wantsLayer = true
        translateSwitchPanel.contentView?.layer?.backgroundColor = NSColor.gray.cgColor
        translateSwitchPanel.contentView?.addSubview(translateSwitchLabel)

        translateSwitchLabel.centerXAnchor.constraint(equalTo: translateSwitchPanel.contentView!.centerXAnchor).isActive = true
        translateSwitchLabel.centerYAnchor.constraint(equalTo: translateSwitchPanel.contentView!.centerYAnchor).isActive = true
        translateSwitchLabel.frame.size = NSMakeSize(58, 26)
    }

    func initInputModePanel() {
        os_log(.debug, log: log, "初始化中英切换面板")
        inputModePanel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 26, height: 26),
                            styleMask: [.nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        
        inputModelabel = NSTextField(frame: NSRect.zero)
        inputModelabel.isEditable = false
        inputModelabel.font = NSFont.systemFont(ofSize: 16)
        inputModelabel.backgroundColor = NSColor.white
        inputModelabel.textColor = NSColor.black

        inputModePanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        inputModePanel.isFloatingPanel = true
        // 确保panel不会成为key window
        inputModePanel.becomesKeyOnlyIfNeeded = true
        inputModePanel.level = .popUpMenu
        inputModePanel.contentView?.wantsLayer = true
        inputModePanel.contentView?.layer?.backgroundColor = NSColor.gray.cgColor
        inputModePanel.contentView?.addSubview(inputModelabel)

        inputModelabel.centerXAnchor.constraint(equalTo: inputModePanel.contentView!.centerXAnchor).isActive = true
        inputModelabel.centerYAnchor.constraint(equalTo: inputModePanel.contentView!.centerYAnchor).isActive = true
        inputModelabel.frame.size = NSMakeSize(26, 26)
    }

    
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {

        os_log(.debug, log: log, "handle,进行输入处理程序")
        if !(sender is IMKTextInput) {
            os_log(.error, log: log, "sender不是IMKTextInput")
            return false
        }
        
        switch event.type {
        case .flagsChanged:
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            //假设shift是单独被按下的
            if modifiers.contains(.shift) && !modifiers.contains(.option)
                && !modifiers.contains(.command) && !modifiers.contains(.control) {
                os_log(.debug, log: log, "shift按下")
                shiftIsDown = true
                shiftPushedAlone = true
                return true
            }
            
            if modifiers.rawValue == 0 {
                //shift键抬起之前没有其他keyDown事件，说明shift是单独被按下的
                if shiftPushedAlone && shiftIsDown {
                    os_log(.debug, log: log, "shift抬起，切换中/英文")
                    self.switchInputMode()
                }
                shiftIsDown = false
                return true
            }
            return false
        case .keyDown:
            return handlerKeyDown(event)
        default:
            return false
        }
        
    }
    
    func isCtrlEnter(_ event: NSEvent!) -> Bool {
        if event.keyCode != 36 {
            os_log(.debug, log: log, "按键不是Enter: %{public}d", event.keyCode)
            return false
        }
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let controlPushedAlone = modifierFlags.contains(.control) && !modifierFlags.contains(.shift) && !modifierFlags.contains(.option) && !modifierFlags.contains(.command)
        if !controlPushedAlone {
            return false
        }
        return true
    }

    
    func isSwitchTranslate(_ event: NSEvent!) -> Bool {
        if event.keyCode != 17 {
            os_log(.debug, log: log, "按键不是t: %{public}d", event.keyCode)
            return false
        }
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let controlPushedAlone = modifierFlags.contains(.control) && !modifierFlags.contains(.shift) && !modifierFlags.contains(.option) && !modifierFlags.contains(.command)
        if !controlPushedAlone {
            return false
        }
        return true
    }
    
    

    func handlerKeyDown(_ event: NSEvent!) -> Bool {
        
        os_log(.debug, log: log, "handle,开始进行输入处理")
        //command + T用来开启/关闭翻译
        if isSwitchTranslate(event) {
            switchTranslate()
            return true
        }
        
        if isCtrlEnter(event) {
            if self.inputProcesser.isEmpty() {
                return false
            }
            buttonClicked(nil)
            return true
        }
        
        //处理组合键
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        // 如果有任何修饰键被按下，就忽略这个事件
        if modifierFlags.contains(.command) ||
           modifierFlags.contains(.option) ||
            modifierFlags.contains(.control) {
            os_log(.debug, log: log, "忽略组合键")
            return false
        }
        
        //说明shift不是单独按下的
        if modifierFlags.contains(.shift) {
            shiftPushedAlone = false
        }

        switch event.keyCode {
        case 36: //Enter
            os_log(.debug, log: log, "handler,处理回车")
            return handlerInput(.enter, keyCode: event.keyCode)
        case 49: //Space
            os_log(.debug, log: log, "handler,处理空格")
            return handlerInput(.space, keyCode: event.keyCode)
        case 51: //backspace
            os_log(.debug, log: log, "handler,处理退格")
            return handlerInput(.backspace, keyCode: event.keyCode)
        case 53:
            os_log(.debug, log: log, "handler,处理Esc")
            self.inputProcesser.clear()
            hideAllWindow()
            return false
        case 115:
            os_log(.debug, log: log, "handler,处理Home")
            return self.inputProcesser.isEmpty() ? false : handlerInput(.home, keyCode: event.keyCode)
        case 119:
            os_log(.debug, log: log, "handler,处理End")
            return self.inputProcesser.isEmpty() ? false : handlerInput(.end, keyCode: event.keyCode)
        case 123:
            os_log(.debug, log: log, "handler,处理方向键<-")
            return self.inputProcesser.isEmpty() ? false : handlerInput(.left, keyCode: event.keyCode)
        case 124:
            os_log(.debug, log: log, "handler,处理方向键->")
            return self.inputProcesser.isEmpty() ? false : handlerInput(.right, keyCode: event.keyCode)
        default:
            os_log(.debug, log: log, "handler,处理其他字符")
            guard let text = event.characters,
                  text.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0.isPunctuation || $0.isSymbol) }) else {
                os_log(.debug, log: log, "不支持的按键: %{public}d", event.keyCode)
                return false
            }
            //跳过非小写字线开头的输入
            guard let ch = text.first else {
                os_log(.debug, log: log, "不支持的按键2: %{public}d", event.keyCode)
                return false
            }
            if ch == "/" {
                os_log(.debug, log: log, "命令开始")
                return handlerInput(.forwardslash, keyCode: event.keyCode)
            }
            if ch.isLowercase {
                return handlerInput(.lower(char: ch), keyCode: event.keyCode)
            }
            if ch.isNumber {
                return handlerInput(.number(num: ch), keyCode: event.keyCode)
            }
            return handlerInput(.other(char: ch), keyCode: event.keyCode)
        }
    }
    
    func handlerInput(_ charType: CharType, keyCode: UInt16) -> Bool {
        //如果非AI模式，并且当前是英文状态，则直接提交之前的输入，并返回
        if !ConfigModel.shared.useAITrans && self.inputProcesser.isEnMode {
            commitText()
            return false
        }
        let inputResult = self.inputProcesser.processInput(charType, keyCode: keyCode)
        switch inputResult {
        case .commit:
            self.commitText()
            self.inputProcesser.clear()
            return true
        case .conditionalCommit:
            if ConfigModel.shared.useAITrans {
                self.setMarkedText()
            } else {
                self.commitText()
            }
            return true
        case .typing:
            self.setMarkedText()
            return true
        case .ignore:
            return false
        case .translate:
            setMarkedText()
            if transPanel.isVisible {
                buttonClicked(nil)
            }
            return true
        case .toggleTranslate:
            setMarkedText()
            switchTranslate()
            return true
        }
    }

    
    override func candidates(_ sender: Any!) -> [Any]! {
        os_log(.debug, log: log, "生成候选词")
        return self.inputProcesser.makeCadidates()
    }

    override func candidateSelected(_ candidateString: NSAttributedString!) {
        os_log(.debug, log: log, "选择候选词: %s", candidateString.string)
        self.inputProcesser.select(candidateString.string)
//        os_log(.debug, log: log, "标记用户输入: %s", self.inputProcesser.composingString)
        hideCadidatesWindow()
        if ConfigModel.shared.useAITrans {
            setMarkedText()
        } else {
            commitText()
        }
    }
    
    func withAttribute(_ text: String) -> NSAttributedString {
        let attrText = NSMutableAttributedString(string: text)
        if !self.inputProcesser.preedit.isEmpty {
            attrText.addAttribute(.font, value: NSFont.systemFont(ofSize: 18, weight: .bold), range: NSMakeRange(self.inputProcesser.breakPos, self.inputProcesser.preedit.count))
        }
        return attrText
    }
    
    
    
    
    func setMarkedText() {
        let attrText = withAttribute(self.inputProcesser.getComposingText())
        os_log(.debug, log: log, "marked text: #%{public}s#", attrText.string)
        self.client().setMarkedText(attrText, selectionRange: NSRange(location: self.inputProcesser.getCursorPos(), length: 0),
                                    replacementRange: NSRange(location: NSNotFound, length: 0))
        self.candidatesWindow.update()
        if self.inputProcesser.hasNoCandidates() {
            os_log(.debug, log: log, "候选词列表为空")
            hideCadidatesWindow()
            if attrText.string.containsChineseCharacters {
                //获取标记文本末尾的位置
                showPanel()
            } else {
                hideTransPanel()
            }
            return
        }
        hideTransPanel()
        showCadidatesWindow()
    }

    
    @objc func buttonClicked(_ sender: NSButton?) {
        os_log(.debug, log: log, "点击翻译")
        self.transBtn.isHidden = true
        self.transProg.isHidden = false
        self.transProg.setPresent(0)
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timerFunc), userInfo: nil, repeats: true)
        let content = self.inputProcesser.getComposingText()
        // 处理按钮点击事件
        switch ConfigModel.shared.modelType {
        case .tongyi:
            TongyiQianWen(apiKey: ConfigModel.shared.apiKey)
                .translate(content, completion: {response in
                    self.commitText(response)
                }, defaultHandler: { () in self.commitText(content) })
        case .gpt3_5_turbo:
            Gpt35Turbo(apiKey: ConfigModel.shared.apiKey)
                .translate(content, completion:{response in
                    self.commitText(response)
                }, defaultHandler: { () in self.commitText(content) })
        default:
            os_log(.debug, log: log, "未知模型，提交当前内容")
            self.commitText(content)
        }
    }
    
    
    func showCadidatesWindow() {
        if Thread.isMainThread {
            self.candidatesWindow.show()
        } else {
            DispatchQueue.main.async {
                self.candidatesWindow.show()
            }
        }
    }
    
    func hideCadidatesWindow() {
        if Thread.isMainThread {
            self.candidatesWindow.hide()
        } else {
            DispatchQueue.main.async {
                self.candidatesWindow.hide()
            }
        }
    }

    
    func showPanel() {
        if Thread.isMainThread {
            doShowPanel()
        } else {
            DispatchQueue.main.async {
                self.doShowPanel()
            }
        }
    }
    
    func findPosition() -> NSRect {
        var inputPos = NSRect()
        let attr = self.client().attributes(forCharacterIndex: 0, lineHeightRectangle: &inputPos)
        var heigthOffset: CGFloat = 26
        if let lineHeight = attr?["IMKLineHeight"] as? NSNumber {
            heigthOffset = CGFloat(lineHeight.floatValue)
        }
        if let screenFrame = NSScreen.main {
            if inputPos.minY > screenFrame.frame.width / 2 {
                inputPos.origin.y = inputPos.minY - heigthOffset
            } else {
                inputPos.origin.y = inputPos.minY + heigthOffset
            }
        }
        return inputPos
    }
    
    
    func doShowPanel() {
        if !ConfigModel.shared.useAITrans {
            return
        }
        let inputPos = findPosition()
        os_log(.debug, log: log, "显示翻译按钮, x: %{public}.1f, y: %{public}.1f, width: %{public}.1f, height: %{public}.1f",
               inputPos.minX, inputPos.minY, inputPos.width, inputPos.height)
        self.transPanel.setFrame(inputPos, display: false)
        os_log(.debug, log: log, "按钮的尺寸, width: %{public}.1f, height: %{public}.1f",
               self.transBtn.frame.width, self.transBtn.frame.height)
        self.transProg.setFrameSize(NSSize(width: self.transBtn.frame.width, height: self.transBtn.frame.height))
        self.transBtn.isHidden = false
        self.transProg.isHidden = true
        self.progress = 0
        self.step = 10
        self.transPanel.orderFront(nil)
    }
    
    
    func hideTransPanel() {
        self.timer?.invalidate()
        if !ConfigModel.shared.useAITrans {
            return
        }
        os_log(.debug, log: log, "隐藏翻译按钮")
        if Thread.isMainThread {
            self.transPanel.orderOut(nil)
        } else {
            // 当前线程不是主线程，需要在主线程上执行 orderOut
            DispatchQueue.main.async {
                self.transPanel.orderOut(nil)
            }
        }
    }
    
    
    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        os_log(.debug, log: log, "启用输入法")
        self.inputProcesser.clear()
        hideTransPanel()
        hideCadidatesWindow()
    }
    
    override func deactivateServer(_ sender: Any!) {
        os_log(.debug, log: log, "停用输入法, sender: %{public}s", sender.debugDescription)
        self.client()?.insertText(self.inputProcesser.getComposingText(),
                                  replacementRange: NSRange(location: NSNotFound, length: 0))
        hideCadidatesWindow()
        hideTransPanel()
    }
    
    func commitText(_ content: String = "") {
        let text = content.isEmpty ? self.inputProcesser.getComposingText() : content
        self.hideTransPanel()
        os_log(.debug, log: log, "提交: %{public}s", text)
        self.client()?.insertText(text, replacementRange: NSRange(location: NSNotFound, length: 0))
        self.inputProcesser.clear()
        hideCadidatesWindow()
    }
    
    
    override func menu() -> NSMenu! {
        let deploy = NSMenuItem(title: NSLocalizedString("Deploy", comment: "Menu item"), action: #selector(deploy), keyEquivalent: "`")
        deploy.target = self
        let settings = NSMenuItem(title: NSLocalizedString("Settings", comment: "Menu item"), action: #selector(showConfigWindow), keyEquivalent: "`")
        settings.target = self

        let menu = NSMenu()
        menu.addItem(deploy)
        menu.addItem(settings)
        return menu
    }
    
    @objc func deploy() {
      NSApp.appDelegate.deploy()
    }

    @objc func showConfigWindow() {
        if let appDelegae = NSApplication.shared.delegate as? AppDelegate, let cfgWindow = appDelegae.cfgWindow {
            if Thread.isMainThread {
                cfgWindow.orderFront(nil)
            } else {
                DispatchQueue.main.async {
                    cfgWindow.orderFront(nil)
                }
            }
        }
    }
    
    override func commitComposition(_ sender: Any!) {
        os_log(.info, log: log, "系统自动提交")
        commitText()
    }
    
    
    override func recognizedEvents(_ sender: Any!) -> Int {
        os_log(.debug, log: log, "recognizedEvents")
        return Int(NSEvent.EventTypeMask.Element(arrayLiteral: .keyDown, .flagsChanged).rawValue)
    }
    
    func switchTranslate() {
        //不能在输入过程中切换翻译开关
        if !self.inputProcesser.isEmpty() {
            return
        }
        //没设置apiKey不能切换翻译开关
        if ConfigModel.shared.apiKey == nil || ConfigModel.shared.apiKey.isEmpty {
            return
        }
        ConfigModel.shared.useAITrans.toggle()
        if ConfigModel.shared.useAITrans {
            self.translateSwitchLabel.stringValue = "翻译开"
        } else {
            self.translateSwitchLabel.stringValue = "翻译关"
        }
        self.translateSwitchPanel.setFrame(findPosition(), display: false)
        if Thread.isMainThread {
            translateSwitchPanel.orderFront(nil)
        } else {
            DispatchQueue.main.async {
                self.translateSwitchPanel.orderFront(nil)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.translateSwitchPanel.orderOut(nil)
        }
    }

    func switchInputMode() {
        self.inputProcesser.toggleEnMode()
        if self.inputProcesser.isEnMode {
            self.inputModelabel.stringValue = "英"
        } else {
            self.inputModelabel.stringValue = "中"
        }
        self.inputModePanel.setFrame(findPosition(), display: false)
        if Thread.isMainThread {
            hideCadidatesWindow()
            hideTransPanel()
            inputModePanel.orderFront(nil)
        } else {
            DispatchQueue.main.async {
                self.inputModePanel.orderFront(nil)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.inputModePanel.orderOut(nil)
        }
    }
    
    func hideAllWindow() {
        hideTransPanel()
        hideCadidatesWindow()
    }
    
    @objc func timerFunc() {
        os_log(.debug, log: log, "进度: %{public}.1f", progress)
        progress += step
        step *= 0.9
        transProg.setPresent(progress)
    }
    
}


