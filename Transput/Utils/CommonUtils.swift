//
//  CommonUtils.swift
//  Transput
//
//  Created by jin junjie on 2024/8/1.
//

import Foundation

extension String {
    var containsChineseCharacters: Bool {
        return self.range(of: "\\p{Han}", options: .regularExpression) != nil
    }
}


func convertPunctuation(_ char: Character) -> Character {
    return switch char {
    case ",":  "，"
    case ".":  "。"
    case "\"": "“"
    case "<":  "《"
    case ">":  "》"
    case "?":  "？"
    case "`":  "·"
    case "\\": "、"
    case " ": " "
    case ":": "："
    default: char
    }
}

extension Array where Element: Comparable {
    mutating func insertSorted(_ newElement: Element) {
        if isEmpty {
            append(newElement)
            return
        }
        
        var left = 0
        var right = count - 1
        
        while left <= right {
            let mid = (left + right) / 2
            if self[mid] == newElement {
                insert(newElement, at: mid)
                return
            } else if self[mid] < newElement {
                left = mid + 1
            } else {
                right = mid - 1
            }
        }
        
        insert(newElement, at: left)
    }
}

func weigthCoef(_ tailCount: Int) -> Int {
    return switch tailCount {
    case 0: 500
    case 1: 50
    case 2: 10
    case 3: 1
    default: 0
    }
}

