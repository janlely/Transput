//
//  CustomProgess.swift
//  Transput
//
//  Created by jin junjie on 2024/8/16.
//

import Foundation
import Cocoa

class CustomProgress: NSView {
    var bgimg: NSImageView!
    var leftimg: NSImageView!
    var maxValue: CGFloat = 0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setupView()
    }
    
    private func setupView() {
        self.layer?.backgroundColor = NSColor.clear.cgColor
        
        bgimg = NSImageView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        bgimg.wantsLayer = true
        bgimg.layer?.borderColor = NSColor.clear.cgColor
        bgimg.layer?.borderWidth = 1
        bgimg.layer?.cornerRadius = 5
        bgimg.layer?.masksToBounds = true
        self.addSubview(bgimg)
        
        leftimg = NSImageView(frame: CGRect(x: 0, y: 0, width: 0, height: self.frame.size.height))
        leftimg.wantsLayer = true
        leftimg.layer?.borderColor = NSColor.clear.cgColor
        leftimg.layer?.borderWidth = 1
        leftimg.layer?.cornerRadius = 5
        leftimg.layer?.masksToBounds = true
        self.addSubview(leftimg)
        
        self.needsDisplay = true
    }
    
    func setPresent(_ present: Double) {
        leftimg.frame = CGRect(x: 0, y: 0, width: self.frame.size.width / maxValue * CGFloat(present), height: self.frame.size.height)
    }
}

