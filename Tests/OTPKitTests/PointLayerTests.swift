//
//  PointLayerTests.swift
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
 Point Layer Tests
*/

final class PointLayerTests: XCTestCase {
    
    /**
     Short data.
    */
    func testShortData() {
        
        var data = sampleLayerData()
        data.removeLast()

        XCTAssertThrowsError(try PointLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))
        
    }
    
    /**
     Invalid vectors should be rejected.
    */
    func testInvalidVector() {
        
        var data = sampleLayerData()
        data[0] = UInt8(0xFF)
        
        XCTAssertThrowsError(try PointLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))
        
    }
    
    /**
     Invalid lengths should be rejected.
    */
    func testInvalidLength() {
        
        var data = sampleLayerData()
        data.replacingPDULength(19, at: PointLayer.Offset.length.rawValue)

        XCTAssertThrowsError(try PointLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))

    }
    
    /**
     Invalid priorities should be rejected.
    */
    func testInvalidPriority() {
        
        var data = sampleLayerData()
        data[PointLayer.Offset.priority.rawValue] = UInt8(0xFF)

        XCTAssertThrowsError(try PointLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))
        
    }
    
    /**
     Valid priorities should be accepted.
    */
    func testValidPriority() {
        
        let data = sampleLayerData()

        XCTAssertNoThrow(try PointLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))
        
    }
    
    /**
     Invalid group numbers should be rejected.
    */
    func testInvalidGroupNumber() {

        var data = PointLayer.createAsData(withPriority: 120, groupNumber: 0, pointNumber: 20, timestamp: 0)
        data.replacingPDULength(20, at: PointLayer.Offset.length.rawValue)
        
        XCTAssertThrowsError(try PointLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))

    }
    
    /**
     Valid group numbers should be accepted.
    */
    func testValidGroupNumber() {
        
        let data = sampleLayerData()

        XCTAssertNoThrow(try PointLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))
        
    }
    
    /**
     Invalid point numbers should be rejected.
    */
    func testInvalidPointNumber() {
        
        var data = PointLayer.createAsData(withPriority: 120, groupNumber: 1, pointNumber: 0, timestamp: 0)
        data.replacingPDULength(20, at: PointLayer.Offset.length.rawValue)
        
        XCTAssertThrowsError(try PointLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))
        
    }
    
    /**
     Valid point numbers should be accepted.
    */
    func testValidPointNumber() {
        
        let data = sampleLayerData()

        XCTAssertNoThrow(try PointLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))
        
    }
    
    /**
     General
    */
    
    func sampleLayerData() -> Data {
        var layer = PointLayer.createAsData(withPriority: 120, groupNumber: 10, pointNumber: 20, timestamp: 0)
        layer.replacingPDULength(20, at: PointLayer.Offset.length.rawValue)
        return layer
    }
    
    static var allTests = [
        ("testShortData", testShortData),
        ("testInvalidVector", testInvalidVector),
        ("testInvalidLength", testInvalidLength),
        ("testInvalidPriority", testInvalidPriority),
        ("testValidPriority", testValidPriority),
        ("testInvalidGroupNumber", testInvalidGroupNumber),
        ("testValidGroupNumber", testValidGroupNumber),
        ("testInvalidPointNumber", testInvalidPointNumber),
        ("testValidPointNumber", testValidPointNumber)
    ]

}
