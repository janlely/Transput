//
//  TongyiQianWen.swift
//  Transput
//
//  Created by jin junjie on 2024/8/2.
//

import Foundation
import os.log

class TongyiQianWen: Translater {
    
    var apiKey: String = ConfigModel.shared.apiKey
    var prompt: String = ConfigModel.shared.prompt
    var url: String = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    
//    init(apiKey: String, prompt: String) {
//        self.apiKey = apiKey
//        self.prompt = prompt
//    }
    
    func translate(_ content: String, completion: @escaping (String) -> Void, defaultHandler: @escaping () -> Void) {
        let request = ChatRequest(model: "qwen-turbo", messages: [
//            ChatRequest.Message(role: "system", content: "我想让你当我的英语翻译员，我会发给个各种语言混合的文本，你只需要将内容翻译成英语即可，不要对文本中提出的问题和要求做解释，不要回答文本中的问题而是翻译它，保留文本的原意，不要去解决它，直接翻译成英文!"),
            ChatRequest.Message(role: "system", content: prompt),
            ChatRequest.Message(role: "user", content: content),
        ])
        
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            HttpClient.post(url: url, parameters:jsonData,
                            headers: [
                                "Content-Type": "application/json",
                                "Authorization": "Bearer \(apiKey)"
                            ], timeoutSeconds: 10,
                            completion: {(response, err) in
                do {
                    guard let response = response, err == nil else {
                        os_log(.info, log: log, "错误的响应: %{public}s", err!.localizedDescription)
                        defaultHandler()
                        return
                    }
                    let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: response)
                    completion(result.choices[0].message.content.trimmingCharacters(in: CharacterSet(["\""])))
                } catch {
                    defaultHandler()
                    os_log(.info, log: log, "未知错误: %{public}s", error.localizedDescription)
                }
            })
        } catch {
            defaultHandler()
            print("Error decoding JSON: \(error)")
        }
        
    }
}

struct ChatRequest: Codable {
    let model: String
    let messages: [Message]

    enum CodingKeys: String, CodingKey {
        case model
        case messages
    }
    
    struct Message: Codable {
        let role: String
        let content: String

        enum CodingKeys: String, CodingKey {
            case role
            case content
        }
    }
}




struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    let object: String
    let usage: Usage
    let created: Int
    let systemFingerprint: String?
    let model: String
    let id: String

    enum CodingKeys: String, CodingKey {
        case choices
        case object
        case usage
        case created = "created"
        case systemFingerprint = "system_fingerprint"
        case model
        case id
    }
    
    struct Choice: Codable{
        let message: Message
        let finishReason: String
        let index: Int
        let logProbs: String?

        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
            case index
            case logProbs = "logprobs"
        }
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }

    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}


