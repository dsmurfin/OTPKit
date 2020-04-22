//
//  OTPLayerTests.swift
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
 OTP Layer Tests
*/

final class OTPLayerTests: XCTestCase {
    
    /**
     Smaller messages should be rejected.
    */
    func testMinSize() {
        
        let data = sampleLayerData()

        XCTAssertThrowsError(try OTPLayer.parse(fromData: data.subdata(in: 0..<data.count-1)))

    }
    
    /**
     Larger messages should be rejected.
    */
    func testMaxSize() {
        
        let data = sampleLayerData()

        let additionalData = Data(repeating: 0, count: UDP.maxMessageLength-data.count+1)
        
        XCTAssertThrowsError(try OTPLayer.parse(fromData: data+additionalData))
        
    }
    
    /**
     Invalid packet identifiers should be rejected.
    */
    func testInvalidPacketIdentifier() {
        
        var data = sampleLayerData()

        data[0] = UInt8(0x00)
        
        XCTAssertThrowsError(try OTPLayer.parse(fromData: data))
        
    }
    
    /**
     Valid packet identifiers should be accepted.
    */
    func testValidPacketIdentifier() {
        
        let data = sampleLayerData()
        
        XCTAssertNoThrow(try OTPLayer.parse(fromData: data))
        
    }
    
    /**
     Invalid vectors should be rejected.
    */
    func testInvalidVector() {
        
        var data = sampleLayerData()

        data[13] = UInt8(0xFF)
        
        XCTAssertThrowsError(try OTPLayer.parse(fromData: data))
        
    }
    
    /**
     Valid vectors should be accepted.
    */
    func testValidVector() {
        
        let data = sampleLayerData()
        
        XCTAssertNoThrow(try OTPLayer.parse(fromData: data))
        
    }
    
    /**
     Invalid footer and length combinations should be ignored.
    */
    func testLengths() {

        var data = sampleLayerData()
            
        // footer length 10, length 0
        data.replacingPDULength(0, at: OTPLayer.Offset.length.rawValue)
        data[OTPLayer.Offset.footerLength.rawValue] = UInt8(0x0A)
        
        XCTAssertThrowsError(try OTPLayer.parse(fromData: data))
        
        // footer length 50, length 14
        data.replacingPDULength(14, at: OTPLayer.Offset.length.rawValue)
        data[OTPLayer.Offset.footerLength.rawValue] = UInt8(0x32)
        
        XCTAssertThrowsError(try OTPLayer.parse(fromData: data))

    }
    
    /**
     General
    */
    
    func sampleLayerData() -> Data {
        let name = "Test".data(paddedTo: ComponentName.maxComponentNameBytes)
        var layer = OTPLayer.createAsData(with: .transformMessage, cid: UUID(), nameData: name, folio: 1, page: 1, lastPage: 1)
        layer.replacingPDULength(63, at: OTPLayer.Offset.length.rawValue)
        return layer
    }
    
    static var allTests = [
        ("testMinSize", testMinSize),
        ("testMaxSize", testMaxSize),
        ("testInvalidPacketIdentifier", testInvalidPacketIdentifier),
        ("testValidPacketIdentifier", testValidPacketIdentifier),
        ("testInvalidVector", testInvalidVector),
        ("testValidVector", testValidVector),
        ("testLengths", testLengths),
    ]

}
