//
//  CleanroomASLTests.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 4/6/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

import XCTest
import Foundation
import CleanroomASL

class CleanroomASLTests: XCTestCase
{
    func testLogging()
    {
        let startTime = NSDate()

        let sender = "com.gilt.cleanroom.tests.ASL"
        let client = ASLClient(sender: sender)

        func testMessageAtPriorityLevel(priorityLevel: ASLPriorityLevel)
            -> String
        {
            return "Logging a test message with \(priorityLevel.priorityString) priority (#\(priorityLevel.rawValue))"
        }

        func writeTestMessageAtPriorityLevel(priorityLevel: ASLPriorityLevel)
        {
            let msg = ASLMessageObject(priorityLevel: priorityLevel, message: testMessageAtPriorityLevel(priorityLevel))
            client.log(msg, logSynchronously: true)
        }

        for priority in ASLPriorityLevel.allValues() {
            writeTestMessageAtPriorityLevel(priority)
        }

        let query = ASLQueryObject()
        query.setQueryKey(.sender, value: sender, operation: .equalTo, modifiers: .none)
        query.setQueryKey(.message, value: nil, operation: .keyExists, modifiers: .none)
        query.setQueryKey(.time, value: Int(startTime.timeIntervalSince1970), operation: .greaterThanOrEqualTo, modifiers: .none)

        let signal = NSCondition()

        signal.lock()
        signal.waitUntilDate(NSDate(timeIntervalSinceNow: 1))
        signal.unlock()

        var gotFinalResult = false

        client.search(query) { result in

            if let result = result {
                print("\(result.timestamp): \(result.message)")
            }

            signal.lock()
            gotFinalResult = result == nil
            if gotFinalResult {
                signal.signal()
            }
            signal.unlock()

            return true
        }

        signal.lock()
        while !gotFinalResult {
            signal.wait()
        }
        signal.unlock()
    }
}
