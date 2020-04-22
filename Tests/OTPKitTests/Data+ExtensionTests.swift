//
//  Data+ExtensionTests.swift
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
 Data Extension Tests
*/

final class DataExtensionTests: XCTestCase {
    
    /**
     Attempts to load a UInt8 from data, and encodes a UInt8 as data.
    */
    func testUInt8DataRoundTrip() {
        
        var data = Data()
            
        data.append(contentsOf: [0x00,0x00,0x08,0x00,0x00])
        
        // the value loaded must be equal to that in data
        let value1 = data.toUInt8(atOffset: 2)
        XCTAssertEqual(value1, 8)
        
        data.append(UInt8(23).data)
        
        // the value loaded must be equal to that in data
        let value2 = data.toUInt8(atOffset: 5)
        XCTAssertEqual(value2, 23)
        
    }
    
    /**
     Attempts to load a UInt16 from data, and encodes a UInt16 as data.
    */
    func testUInt16DataRoundTrip() {
        
        var data = Data()
            
        data.append(contentsOf: [0x00,0x00,0x08,0x00,0x00])
        
        // the value loaded must be equal to that in data
        let value1 = data.toUInt16(atOffset: 1)
        XCTAssertEqual(value1, 8)
        
        data.append(UInt16(23).data)
        
        // the value loaded must be equal to that in data
        let value2 = data.toUInt16(atOffset: 5)
        XCTAssertEqual(value2, 23)
        
    }
    
    /**
     Attempts to load a UInt32 from data, and encodes a UInt32 as data.
    */
    func testUInt32DataRoundTrip() {
        
        var data = Data()
            
        data.append(contentsOf: [0x00,0x00,0x08,0x00,0x00])
        
        // the value loaded must be equal to that in data
        let value1 = data.toUInt32(atOffset: 1)
        XCTAssertEqual(value1, 524288)
        
        data.append(UInt32(23).data)
        
        // the value loaded must be equal to that in data
        let value2 = data.toUInt32(atOffset: 5)
        XCTAssertEqual(value2, 23)
        
    }
    
    /**
     Attempts to load a Int32 from data, and encodes a Int32 as data.
    */
    func testInt32DataRoundTrip() {
        
        var data = Data()
            
        data.append(contentsOf: [0x00,0x00,0x08,0x00,0x00])
        
        // the value loaded must be equal to that in data
        let value1 = data.toInt32(atOffset: 1)
        XCTAssertEqual(value1, 524288)
        
        data.append(Int32(23).data)
        
        // the value loaded must be equal to that in data
        let value2 = data.toInt32(atOffset: 5)
        XCTAssertEqual(value2, 23)
        
    }
    
    /**
     Attempts to load a UInt64 from data, and encodes a UInt32 as data.
    */
    func testUInt64DataRoundTrip() {
        
        var data = Data()
            
        data.append(contentsOf: [0x00,0x00,0x08,0x00,0x00,0x00,0x00,0x00,0x00])
        
        // the value loaded must be equal to that in data
        let value1 = data.toUInt64(atOffset: 1)
        XCTAssertEqual(value1, 2251799813685248)
        
        data.append(UInt64(23).data)
        
        // the value loaded must be equal to that in data
        let value2 = data.toUInt64(atOffset: 9)
        XCTAssertEqual(value2, 23)
        
    }
    
    /**
     Attempts to encode a UUID to data, and load it from data.
    */
    func testUUIDDataRoundTrip() {
        
        var data = Data()
        
        let uuid = UUID()
        
        data.append(contentsOf: [0x00,0x00,0x08,0x00,0x00])
        
        data.append(uuid.data)
        
        let loadedUUID = data.toUUID(atOffset: 5)
            
        XCTAssertEqual(uuid, loadedUUID)
        
    }
    
    /**
     Attempts to encode a String to data, and load it from data.
    */
    func testStringDataRoundTrip() {
        
        var data = Data()
        
        let string = "This is a test string"

        data.append(contentsOf: [0x00,0x00,0x08,0x00,0x00])
        
        data.append(string.data(paddedTo: 21))
        
        let loadedString = data.toString(ofLength: 21, atOffset: 5)
            
        XCTAssertEqual(string, loadedString)
        
        let emojiString = "😀🇬🇧🇺🇸🏳️‍🌈"
        
        let emojiData = emojiString.data(paddedTo: 32)

        let loadedEmojiString = emojiData.toString(ofLength: 32, atOffset: 0)
        
        XCTAssertEqual("😀🇬🇧🇺🇸", loadedEmojiString)
        
    }
    
    /**
     Attempts to encode a Module Identifier to data, and load it from data.
    */
    func testModuleIdentifierDataRoundTrip() {
        
        var data = Data()
        
        let moduleIdentifier = OTPModuleIdentifier(manufacturerID: 0x0001, moduleNumber: 0x9999)

        data.append(contentsOf: [0x00,0x00,0x08,0x00,0x00])
        
        data.append(moduleIdentifier.data)
        
        let loadedModuleIdentifier = data.toModuleIdentifier(atOffset: 5)
            
        XCTAssertEqual(moduleIdentifier, loadedModuleIdentifier)
        
    }
    
    /**
     Attempts to encode a Address Point Description to data, and load it from data.
    */
    func testAddressPointDescriptionDataRoundTrip() {
        
        var data = Data()
        
        let addressPointDescription = AddressPointDescription(address: OTPAddress(system: 1, group: 2, point: 3), pointName: "Test Point")

        data.append(contentsOf: [0x00,0x00,0x08,0x00,0x00])
        
        data.append(addressPointDescription.data)
        
        let loadedAddressPointDescription = data.toAddressPointDescription(atOffset: 5)
        
        XCTAssertEqual(addressPointDescription, loadedAddressPointDescription)
        
    }
    
    /**
     Attempts to replace a PDU Length field in the data.
    */
    func testReplacePDULengthInDataRoundTrip() {
        
        var data = Data()
        
        let length: OTPPDULength = 234

        data.append(contentsOf: [0x00,0x00,0x08,0x00,0x00])
        
        data.replacingPDULength(length, at: 3)

        let loadedPDULength: OTPPDULength? = data.toUInt16(atOffset: 3)

        XCTAssertEqual(length, loadedPDULength)
        
    }
    
    /**
     Attempts create options flags, and retrieve matching values.
    */
    func testOptionsFlags() {
        
        let seven: UInt8 = 0b10000000

        XCTAssertTrue(seven.optionsFlags[7])
        
        let five: UInt8 = 0b00100000
        
        XCTAssertTrue(five.optionsFlags[5])
        
        let all: UInt8 = 255
        
        XCTAssertEqual(all.optionsFlags.filter { $0 == true }.count, 8)
        
    }
    
    static var allTests = [
        ("testUInt8DataRoundTrip", testUInt8DataRoundTrip),
        ("testUInt16DataRoundTrip", testUInt16DataRoundTrip),
        ("testUInt32DataRoundTrip", testUInt32DataRoundTrip),
        ("testUUIDDataRoundTrip", testUUIDDataRoundTrip),
        ("testStringDataRoundTrip", testStringDataRoundTrip),
        ("testModuleIdentifierDataRoundTrip", testModuleIdentifierDataRoundTrip),
        ("testAddressPointDescriptionDataRoundTrip", testAddressPointDescriptionDataRoundTrip),
        ("testReplacePDULengthInDataRoundTrip", testReplacePDULengthInDataRoundTrip),
        ("testOptionsFlags", testOptionsFlags)
    ]

}
