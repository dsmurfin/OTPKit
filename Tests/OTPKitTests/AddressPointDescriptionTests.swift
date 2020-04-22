//
//  AddressPointDescriptionsTests.swift
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
 Address Point Description Tests
*/

final class AddressPointDescriptionTests: XCTestCase {
    
    /**
     It should be possible to create an Address Point Description using an Address and Point Name.
    */
    func testCreateWithAddressAndName() {

        let name = PointName("TestPointName")

        let addressPointDescription = AddressPointDescription(address: OTPAddress(system: 1, group: 1, point: 1), pointName: name)
        
        XCTAssertEqual(addressPointDescription.address, OTPAddress(system: 1, group: 1, point: 1))
        XCTAssertEqual(addressPointDescription.pointName, "TestPointName")
        
    }
    
    /**
     Addresses Point Descriptions should be ordered correctly.
    */
    func testAddressSort() {
        
        let addressPointDescription0 = AddressPointDescription(address: OTPAddress(system: 1, group: 1, point: 1), pointName: "TestPointName")
        let addressPointDescription1 = AddressPointDescription(address: OTPAddress(system: 1, group: 2, point: 1), pointName: "TestPointName")
        let addressPointDescription2 = AddressPointDescription(address: OTPAddress(system: 1, group: 2, point: 2), pointName: "TestPointName")
        let addressPointDescription3 = AddressPointDescription(address: OTPAddress(system: 2, group: 2, point: 2), pointName: "TestPointName")

        let addressPointDescriptions = [addressPointDescription2, addressPointDescription3, addressPointDescription0, addressPointDescription1].sorted()

        XCTAssertEqual(addressPointDescriptions[0], addressPointDescription0)
        XCTAssertEqual(addressPointDescriptions[1], addressPointDescription1)
        XCTAssertEqual(addressPointDescriptions[2], addressPointDescription2)
        XCTAssertEqual(addressPointDescriptions[3], addressPointDescription3)

    }
    
    static var allTests = [
        ("testCreateWithAddressAndName", testCreateWithAddressAndName),
        ("testAddressSort", testAddressSort)
    ]

}
