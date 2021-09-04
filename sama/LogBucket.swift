//
//  LogBucket.swift
//  sama
//
//  Created by Viktoras Laukevičius on 9/4/21.
//

import Foundation

class LogBucket {
    static let shared = LogBucket()

    private var messages: [String] = []

    func log(_ msg: String) {
        messages.append(msg)
    }

    func stringify() -> String {
        return messages.joined(separator: "\n")
    }
}
