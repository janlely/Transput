//
//  ConfigModel.swift
//  Transput
//
//  Created by jin junjie on 2024/8/4.
//

import Foundation

class ConfigModel {
    static let shared = ConfigModel()
    private init() {}
    
//    var modelType: LLMType?
    var url: String!
    var apiKey: String!
    var prompt: String!
    var useAITrans: Bool = false
    
}


enum LLMType {
    case tongyi
    case gpt3_5_turbo
    case deepseek_v3
}
