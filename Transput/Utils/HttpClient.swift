//
//  HttpClient.swift
//  Transput
//
//  Created by jin junjie on 2024/8/2.
//

import Foundation

class HttpClient {
    
    static func post(url: String, parameters: Data,
                     headers: [String:String],
                     timeoutSeconds: TimeInterval,
                     completion: @escaping (Data?, Error?) -> Void) {
        
        guard let url = URL(string: url) else {
            completion(nil, NSError(domain: "Invalid URL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
            
        request.httpBody = parameters
        // 设置超时时间
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutSeconds
        let session = URLSession(configuration: configuration)
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error as? NSError {
                completion(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, NSError(domain: "Unexpected response code", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unexpected response code"]))
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(nil, NSError(domain: "Unexpected response code", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected response code"]))
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "No data received", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            // 解析JSON数据为字典
            completion(data, nil)
        }
        
        task.resume()
    }
}

