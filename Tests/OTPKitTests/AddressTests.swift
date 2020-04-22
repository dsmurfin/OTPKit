//
//  AddressTests.swift
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
 Address Tests
*/

final class AddressTests: XCTestCase {
    
    /**
     Invalid System Numbers should be rejected.
    */
    func testSystemNumberValidity() {
        
        let systemNumberInvalidLow: SystemNumber = 0
        let systemNumberInvalidHigh: SystemNumber = 201
        let systemNumberValidLow: SystemNumber = 1
        let systemNumberValidHigh: SystemNumber = 200

        XCTAssertThrowsError(try systemNumberInvalidLow.validSystemNumber())
        XCTAssertThrowsError(try systemNumberInvalidHigh.validSystemNumber())
        XCTAssertNoThrow(try systemNumberValidLow.validSystemNumber())
        XCTAssertNoThrow(try systemNumberValidHigh.validSystemNumber())
        
    }
    
    /**
     Invalid Group Numbers should be rejected.
    */
    func testGroupNumberValidity() {
        
        let groupNumberInvalidLow: GroupNumber = 0
        let groupNumberInvalidHigh: GroupNumber = 60001
        let groupNumberValidLow: GroupNumber = 1
        let groupNumberValidHigh: GroupNumber = 60000

        XCTAssertThrowsError(try groupNumberInvalidLow.validGroupNumber())
        XCTAssertThrowsError(try groupNumberInvalidHigh.validGroupNumber())
        XCTAssertNoThrow(try groupNumberValidLow.validGroupNumber())
        XCTAssertNoThrow(try groupNumberValidHigh.validGroupNumber())
        
    }
    
    /**
     Invalid Point Numbers should be rejected.
    */
    func testPointNumberValidity() {
        
        let pointNumberInvalidLow: PointNumber = 0
        let pointNumberInvalidHigh: PointNumber = 4000000001
        let pointNumberValidLow: PointNumber = 1
        let pointNumberValidHigh: PointNumber = 4000000000

        XCTAssertThrowsError(try pointNumberInvalidLow.validPointNumber())
        XCTAssertThrowsError(try pointNumberInvalidHigh.validPointNumber())
        XCTAssertNoThrow(try pointNumberValidLow.validPointNumber())
        XCTAssertNoThrow(try pointNumberValidHigh.validPointNumber())
        
    }
    
    /**
     It should be possible to create an Address.
    */
    func testCreateAddress() {
        
        do {
        
            let addressInternal = OTPAddress(system: 1, group: 2, point: 3)
            
            let addressShort = try OTPAddress(1,2,3)
            let addressLong = try OTPAddress(systemNumber: 3, groupNumber: 4, pointNumber: 5)

            XCTAssertEqual(addressInternal.systemNumber, 1)
            XCTAssertEqual(addressInternal.groupNumber, 2)
            XCTAssertEqual(addressInternal.pointNumber, 3)
            XCTAssertEqual(addressShort.systemNumber, 1)
            XCTAssertEqual(addressShort.groupNumber, 2)
            XCTAssertEqual(addressShort.pointNumber, 3)
            XCTAssertEqual(addressLong.systemNumber, 3)
            XCTAssertEqual(addressLong.groupNumber, 4)
            XCTAssertEqual(addressLong.pointNumber, 5)
            
        } catch {
            XCTAssert(false)
        }
        
    }
    
    /**
     Invalid Addresses should be rejected.
    */
    func testAddressValidity() {

        let addressInvalidSystem = OTPAddress(system: 0, group: 1, point: 1)
        let addressInvalidGroup = OTPAddress(system: 1, group: 0, point: 1)
        let addressInvalidPoint = OTPAddress(system: 1, group: 1, point: 0)

        let addressValidLow = OTPAddress(system: 1, group: 1, point: 1)
        let addressValidHigh = OTPAddress(system: 200, group: 60000, point: 4000000000)

        XCTAssertThrowsError(try addressInvalidSystem.isValid())
        XCTAssertThrowsError(try addressInvalidGroup.isValid())
        XCTAssertThrowsError(try addressInvalidPoint.isValid())
        XCTAssertNoThrow(try addressValidLow.isValid())
        XCTAssertNoThrow(try addressValidHigh.isValid())
        
    }
    
    /**
     Addresses should be ordered correctly.
    */
    func testAddressSort() {

        let address0 = OTPAddress(system: 1, group: 1, point: 1)
        let address1 = OTPAddress(system: 1, group: 2, point: 1)
        let address2 = OTPAddress(system: 1, group: 2, point: 2)
        
        let addresses = [address2, address0, address1].sorted()

        XCTAssertEqual(addresses[0], address0)
        XCTAssertEqual(addresses[1], address1)
        XCTAssertEqual(addresses[2], address2)
        
    }
    
    static var allTests = [
        ("testSystemNumberValidity", testSystemNumberValidity),
        ("testGroupNumberValidity", testGroupNumberValidity),
        ("testPointNumberValidity", testPointNumberValidity),
        ("testCreateAddress", testCreateAddress),
        ("testAddressValidity", testAddressValidity),
        ("testAddressSort", testAddressSort)
    ]

}
