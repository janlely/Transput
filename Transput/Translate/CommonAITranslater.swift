//
//  CommonAITranslater.swift
//  Transput
//
//  Created by jin junjie on 2025/3/7.
//

import Foundation
import os.log

class CommonAITranslater: Translater {
    
    static let shared = CommonAITranslater()
    
    var apiKey: String = ConfigModel.shared.apiKey
    var prompt: String = ConfigModel.shared.prompt
//    var url: String = "https://aihubmix.com/v1/chat/completions"
    var url: String = ConfigModel.shared.url
    
    
    
    func translate(_ content: String, completion: @escaping (String) -> Void, defaultHandler: @escaping () -> Void) {
        let request = ChatRequest(model: "qwen-turbo", messages: [
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
