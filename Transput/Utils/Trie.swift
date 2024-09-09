//
//  Trie.swift
//  Transput
//
//  Created by jin junjie on 2024/7/30.
//

import Foundation
import os.log

class TrieNode {
    var children: [String: TrieNode] = [:]
    var code: String?
    var words: [String] = []
    func append(_ word: String) {
        self.words.append(word)
    }
    
    enum CodingKeys: String, CodingKey {
        case children, code, words
    }
    
    init(_ code: String) {
        self.code = code
    }
    
}


class Trie {
    
//    private var root: TrieNode = TrieNode(0)
    
    static func loadFromText(_ filename: String, root: TrieNode?) -> TrieNode? {
        
        guard let path = Bundle.main.path(forResource: filename, ofType: nil) else {
            os_log(.error, log: log, "Cannot find file: \(filename)")
            return nil
        }
        
        guard let filePointer = fopen(path, "r") else {
            os_log(.error, log: log, "Error opening file")
            return nil
        }
        defer {
            fclose(filePointer)
        }
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        
        let result = root == nil ? TrieNode("") : root!
        while fgets(buffer, Int32(bufferSize), filePointer) != nil {
            let line = String(cString: buffer)
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmedLine.split(separator: " ", maxSplits: 2)
            if parts.count == 2 {
                var codes: [String] = String(parts[0]).split(separator: "'").map { String($0) }
                let word = String(parts[1])
                Trie.insert(root: result, codes: &codes, word: word)
            }
        }
        return result
    }
    
    
    static func insert(root: TrieNode, codes: inout [String], word: String) {
        guard let head = codes.first else {
            return
        }
        if root.children[head] == nil {
            root.children[head] = TrieNode(head)
        }
        codes.removeFirst()
        if codes.isEmpty {
            root.children[head]!.append(word)
        }
        insert(root: root.children[head]!, codes: &codes, word: word)
    }
    
    static func search(root: TrieNode, codes: [String]) -> [String] {
        guard let head = codes.first, root.children[head] != nil else {
            return []
        }
        let tails = codes.dropFirst()
        if tails.isEmpty {
            return root.children[head]!.words
        }
        return search(root: root.children[head]!, codes: codes)
    }
}
