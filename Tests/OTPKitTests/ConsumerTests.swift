//
//  ConsumerTests.swift
//
//  Copyright (c) 2020 Daniel Murfin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import XCTest
@testable import OTPKit

/**
 Producer Tests
*/

final class ConsumerTests: XCTestCase {
    
    /**
     It should be possible to create a Consumer with a name, interface, module types, observed system, delegate queue and delegate interval.
    */
    func testCreateConsumerWithName() {
        
        let componentName = ComponentName("TestName")

        let consumer = OTPConsumer(name: componentName, interface: "", moduleTypes: [], observedSystems: [1], delegateQueue: DispatchQueue.main, delegateInterval: 50)
        
        // the consumer should have the name provided
        XCTAssertEqual(componentName, consumer.name)
        
    }
    
    /**
     It should be possible to create a Consumer with a name, CID, interface, module types, observed system, delegate queue and delegate interval.
    */
    func testCreateConsumerWithCID() {
        
        let componentName = ComponentName("TestName")
        let cid = CID()

        let consumer = OTPConsumer(name: componentName, cid: cid, interface: "", moduleTypes: [], observedSystems: [1], delegateQueue: DispatchQueue.main, delegateInterval: 50)

        // the consumer should have the cid provided
        XCTAssertEqual(cid, consumer.cid)
        
    }

    static var allTests = [
        ("testCreateConsumerWithName", testCreateConsumerWithName),
        ("testCreateConsumerWithCID", testCreateConsumerWithCID)
    ]
    
}
