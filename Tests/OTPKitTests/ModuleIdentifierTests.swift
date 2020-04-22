//
//  ModuleIdentifierTests.swift
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
 Module Identifier Tests
*/

final class ModuleIdentifierTests: XCTestCase {
    
    /**
     Creates a Module Identifier
    */
    func testCreateModuleIdentifier() {
        
        let moduleIdentifier = OTPModuleIdentifier(manufacturerID: 0x0001, moduleNumber: 0x0002)
        
        XCTAssertEqual(moduleIdentifier.manufacturerID, 0x0001)
        XCTAssertEqual(moduleIdentifier.moduleNumber, 0x0002)
        
    }
    
    /**
     Module Identifiers should be ordered correctly.
    */
    func testModuleIdentifiersSort() {
        
        let moduleIdentifier0 = OTPModuleIdentifier(manufacturerID: 0x0001, moduleNumber: 0x0002)
        let moduleIdentifier1 = OTPModuleIdentifier(manufacturerID: 0x0001, moduleNumber: 0x0003)
        let moduleIdentifier2 = OTPModuleIdentifier(manufacturerID: 0x0002, moduleNumber: 0x0002)

        let moduleIdentifiers = [moduleIdentifier2, moduleIdentifier0, moduleIdentifier1].sorted()

        XCTAssertEqual(moduleIdentifiers[0], moduleIdentifier0)
        XCTAssertEqual(moduleIdentifiers[1], moduleIdentifier1)
        XCTAssertEqual(moduleIdentifiers[2], moduleIdentifier2)
        
    }
    
    /**
     Creates a Module Identifier Notification
    */
    func testCreateModuleIdentifierNotification() {
        
        let moduleIdentifier = OTPModuleIdentifier(manufacturerID: 0x0001, moduleNumber: 0x0002)
        let now = Date()
        
        let moduleIdentifierNotification = ModuleIdentifierNotification(moduleIdentifier: moduleIdentifier, notified: now)
        
        XCTAssertEqual(moduleIdentifierNotification.moduleIdentifier.manufacturerID, 0x0001)
        XCTAssertEqual(moduleIdentifierNotification.moduleIdentifier.moduleNumber, 0x0002)
        XCTAssertEqual(moduleIdentifierNotification.notified, now)
        
    }
    
    /**
     Module Identifier Notifications should be ordered correctly.
    */
    func testModuleIdentifierNotificationsSort() {
        
        let moduleIdentifier0 = OTPModuleIdentifier(manufacturerID: 0x0001, moduleNumber: 0x0002)
        let moduleIdentifier1 = OTPModuleIdentifier(manufacturerID: 0x0001, moduleNumber: 0x0003)
        let moduleIdentifier2 = OTPModuleIdentifier(manufacturerID: 0x0002, moduleNumber: 0x0002)
        
        let now = Date()

        let moduleIdentifierNotification0 = ModuleIdentifierNotification(moduleIdentifier: moduleIdentifier0, notified: now)
        let moduleIdentifierNotification1 = ModuleIdentifierNotification(moduleIdentifier: moduleIdentifier1, notified: now)
        let moduleIdentifierNotification2 = ModuleIdentifierNotification(moduleIdentifier: moduleIdentifier2, notified: now)

        
        let moduleIdentifierNotifications = [moduleIdentifierNotification2, moduleIdentifierNotification0, moduleIdentifierNotification1].sorted()

        XCTAssertEqual(moduleIdentifierNotifications[0], moduleIdentifierNotification0)
        XCTAssertEqual(moduleIdentifierNotifications[1], moduleIdentifierNotification1)
        XCTAssertEqual(moduleIdentifierNotifications[2], moduleIdentifierNotification2)
        
    }
    
    static var allTests = [
        ("testCreateModuleIdentifier", testCreateModuleIdentifier),
        ("testModuleIdentifiersSort", testModuleIdentifiersSort),
        ("testCreateModuleIdentifierNotification", testCreateModuleIdentifierNotification),
        ("testModuleIdentifierNotificationsSort", testModuleIdentifierNotificationsSort)
    ]

}
