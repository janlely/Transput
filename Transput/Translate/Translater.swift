//
//  Translater.swift
//  Transput
//
//  Created by jin junjie on 2024/8/2.
//

import Foundation


protocol Translater {
    func translate(_ content: String, completion: @escaping (String) -> Void, defaultHandler: @escaping () -> Void)
}
