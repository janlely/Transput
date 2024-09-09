//
//  TransputTests.swift
//  TransputTests
//
//  Created by β α on 2021/09/07.
//

import XCTest
@testable import Transput

class TransputTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func textExample3() throws {
    }
    
    func testExample2() throws {
        
        let inputHandler = InputProcesser()
        inputHandler.initialize(rimeBridge: NSApp.appDelegate.rimeBridge)
        
        let _ = inputHandler.processInput(.lower(char: "n"), keyCode: 0x00)
        var text = inputHandler.getComposingText()
        assert(text == "n")
        
        let _ = inputHandler.processInput(.lower(char: "i"), keyCode: 0x00)
        text = inputHandler.getComposingText()
        assert(text == "ni")
        
        let _ = inputHandler.processInput(.lower(char: "h"), keyCode: 0x00)
        text = inputHandler.getComposingText()
        assert(text == "ni h")
        
        let _ = inputHandler.processInput(.lower(char: "a"), keyCode: 0x00)
        text = inputHandler.getComposingText()
        assert(text == "ni ha")
        
        let _ = inputHandler.processInput(.lower(char: "o"), keyCode: 0x00)
        text = inputHandler.getComposingText()
        assert(text == "ni hao")
        
        let _ = inputHandler.processInput(.left, keyCode: 123)
        text = inputHandler.getComposingText()
        assert(text == "nihao")
        
        let res = inputHandler.processInput(.number(num: "1"), keyCode: 0x12)
        text = inputHandler.getComposingText()

    }

    func testExample1() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let inputHandler = InputProcesser()
        inputHandler.initialize(rimeBridge: NSApp.appDelegate.rimeBridge)
        
        let _ = inputHandler.processInput(.lower(char: "a"), keyCode: 0x00)
        var text = inputHandler.getComposingText()
        assert(text == "a")
        
        let _ = inputHandler.processInput(.number(num: "1"), keyCode: 0x12)
        text = inputHandler.getComposingText()
        assert(text == "啊")

        let _ = inputHandler.processInput(.number(num: "2"), keyCode: 0x13)
        text = inputHandler.getComposingText()
        assert(text == "啊2")

        
        let _ = inputHandler.processInput(.lower(char: "a"), keyCode: 0x00)
        text = inputHandler.getComposingText()
        assert(text == "啊2a")
        
        let _ = inputHandler.processInput(.number(num: "1"), keyCode: 0x12)
        text = inputHandler.getComposingText()
        assert(text == "啊2啊")
        
        inputHandler.toggleEnMode()
        let _ = inputHandler.processInput(.lower(char: "a"), keyCode: 0x00)
        text = inputHandler.getComposingText()
        assert(text == "啊2啊a")
        
        let _ = inputHandler.processInput(.number(num: "1"), keyCode: 0x12)
        text = inputHandler.getComposingText()
        assert(text == "啊2啊a1")

    }

    
}