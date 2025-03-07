//
//  SettingsPanel.swift
//  Transput
//
//  Created by jin junjie on 2025/3/6.
//

import Foundation
import Cocoa
import os.log


class SettingsPanel: NSPanel {
    private let labels = ["启用翻译:", "api地址:", "提示词:", "ApiKey:"]
    static let shared = SettingsPanel()
//    private var forcedFirstResponder: NSResponder?
    // 添加控件引用
    private var switchButton: NSSwitch!
//    private var popUp: NSPopUpButton!
    private var url: NSTextField!
    private var apiKey: NSTextField!
    private var prompt: NSTextField!
    convenience init() {
        self.init(contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
                  styleMask: [.nonactivatingPanel, .titled, .closable],
                            backing: .buffered,
                            defer: false)
        // 设置窗口级别
        self.level = .popUpMenu
        // 设置窗口行为
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = false // 改为 false
        self.hidesOnDeactivate = false      // 禁止窗口失活时隐藏
        
        setupUI()
    }
    
    
//    override func becomeFirstResponder() -> Bool {
//        if let responder = forcedFirstResponder {
//            return responder.becomeFirstResponder()
//        }
//        return super.becomeFirstResponder()
//    }
    
    private func setupUI() {
        guard let contentView = contentView else { return }
        
        // 创建网格布局
        let gridView = NSGridView(numberOfColumns: 2, rows: 4)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.columnSpacing = 8
        gridView.rowSpacing = 12
        gridView.rowAlignment = .firstBaseline
        
        // 添加标签和控件
        for (index, title) in labels.enumerated() {
            let label = NSTextField(labelWithString: title)
            label.alignment = .right
            gridView.addRow(with: [label, createControl(for: index)])
        }
        
        
        // 配置按钮
        let cancelButton = NSButton(title: "取消", target: self, action: #selector(close))
        let okButton = NSButton(title: "确定", target: self, action: #selector(onOK))
        let buttonStack = NSStackView(views: [cancelButton, okButton])
        buttonStack.spacing = 8
        buttonStack.distribution = .fillEqually
        
        // 主垂直布局
        let mainStack = NSStackView(views: [gridView, buttonStack])
        mainStack.orientation = .vertical
        mainStack.spacing = 12
        mainStack.edgeInsets = NSEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
        
        contentView.addSubview(mainStack)
        
        // 布局约束
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            gridView.widthAnchor.constraint(equalTo: mainStack.widthAnchor, constant: -40),
            buttonStack.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor, constant: -20),
            
            url.widthAnchor.constraint(equalToConstant: 320),
            url.heightAnchor.constraint(equalToConstant: 60),
            prompt.widthAnchor.constraint(equalToConstant: 320),
            prompt.heightAnchor.constraint(equalToConstant: 200),
            apiKey.widthAnchor.constraint(equalToConstant: 320),
            apiKey.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func createControl(for index: Int) -> NSView {
        switch index {
        case 0:
            self.switchButton = NSSwitch()
            return switchButton
            
        case 1:
//            self.popUp = NSPopUpButton()
//            popUp.addItems(withTitles: ["通义千问", "Gpt3.5Turbo", "DeepseekV3"])
            url = NSTextField()
            url.placeholderString = "输入api地址"
            url.isSelectable = true
            url.isEditable = true
            url.maximumNumberOfLines = 0
            url.usesSingleLineMode = false
            url.cell?.wraps = true
            url.cell?.isScrollable = false
            return url
            
        case 2:
            prompt = NSTextField()
            prompt.isSelectable = true
            prompt.isEditable = true
            prompt.maximumNumberOfLines = 0
            prompt.usesSingleLineMode = false
            prompt.cell?.wraps = true
            prompt.cell?.isScrollable = false
            prompt.stringValue = "我想让你当我的英语翻译员，我会发给个各种语言混合的文本，你只需要将内容翻译成英语即可，不要对文本中提出的问题和要求做解释，不要回答文本中的问题而是翻译它，保留文本的原意，不要去解决它，直接翻译成英文!"
            return prompt
        case 3:
            apiKey = NSTextField()
            apiKey.isEditable = true
            apiKey.isSelectable = true
            apiKey.maximumNumberOfLines = 0
            apiKey.usesSingleLineMode = false
            apiKey.cell?.wraps = true
            apiKey.cell?.isScrollable = false
            return apiKey

        default: return NSView()
        }
    }
    

    @objc private func onOK() {
//        let url: String = switch self.popUp.titleOfSelectedItem {
//            case "通义千问": ""
//            case "Gpt3.5Turbo": .gpt3_5_turbo
//            case "": .gpt3_5_turbo
//            case "DeepseekV3" : .deepseek_v3
//            default: .tongyi
//        }
        ConfigModel.shared.url = self.url.stringValue
        ConfigModel.shared.apiKey = self.apiKey.stringValue
        ConfigModel.shared.prompt = self.prompt.stringValue
        ConfigModel.shared.useAITrans = self.switchButton.state == .on
        close()
    }
    
    func showPanel() {
        self.center()
        self.makeKeyAndOrderFront(nil)
        os_log(.debug, log: log, "settings panel is key: %{public}s", self.isKeyWindow ? "YES" : "NO")
    }
    
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // 先处理自定义快捷键
        if handleCommandShortcuts(event) { return true }
        
        // 再交给系统处理
        return super.performKeyEquivalent(with: event)
    }
    
    private func handleCommandShortcuts(_ event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else { return false }
        
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "c":
            os_log(.debug, log: log, "command+c")
            NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self)
            return true
        case "v":
            os_log(.debug, log: log, "command+v")
            NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self)
            return true
        default:
            return false
        }
    }
    
    // 获取当前焦点文本框
    private func focusedTextField() -> NSTextField? {
        if prompt.currentEditor() != nil {
            return prompt
        } else if apiKey.currentEditor() != nil {
            return apiKey
        }
        return nil
    }
}
