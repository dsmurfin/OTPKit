//
//  ModuleLayerTests.swift
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
 Module Layer Tests
*/

final class ModuleLayerTests: XCTestCase {
    
    /**
     Short data.
    */
    func testShortData() {
        
        let data = Data([0x00, 0x00, 0x00, 0x00, 0x00])

        XCTAssertThrowsError(try ModuleLayer.parse(fromData: data, moduleTypes: []))
        
    }
    
    /**
     Invalid lengths should be rejected.
    */
    func testInvalidLength() {
        
        let data = Data([0x00, 0x00, 0x00, 0x09, 0x00, 0x00, 0x00, 0x00])

        XCTAssertThrowsError(try ModuleLayer.parse(fromData: data, moduleTypes: []))
        
    }
    
    /**
     Valid lengths should be accepted.
    */
    func testValidLength() {
        
        let data = Data([0x00, 0x00, 0x00, 0x04, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        
        do {
            
            let result = try ModuleLayer.parse(fromData: data, moduleTypes: [OTPModulePosition.self])
            
            XCTAssertEqual(result.length, 19)
            
        } catch {
            XCTAssert(false)
        }
        
    }
    
    static var allTests = [
        ("testShortData", testShortData),
        ("testInvalidLength", testInvalidLength),
        ("testValidLength", testValidLength)
    ]

}
