//
//  TransformLayer.swift
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
 Transform Layer Tests
*/

final class TransformLayerTests: XCTestCase {
    
    /**
     Short data.
    */
    func testShortData() {
        
        var data = sampleLayerData()
        data.removeLast()

        XCTAssertThrowsError(try TransformLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))
        
    }
    
    /**
     Invalid vectors should be rejected.
    */
    func testInvalidVector() {
        
        var data = sampleLayerData()
        data[0] = UInt8(0xFF)
        
        XCTAssertThrowsError(try TransformLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))

    }
    
    /**
     Invalid lengths should be rejected.
    */
    func testInvalidLength() {
        
        var data = sampleLayerData()
        data.replacingPDULength(13, at: TransformLayer.Offset.length.rawValue)

        XCTAssertThrowsError(try TransformLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))

    }
    
    /**
     Invalid system numbers should be rejected.
    */
    func testInvalidSystemNumber() {
        
        var data = sampleLayerData()
        data[TransformLayer.Offset.systemNumber.rawValue] = UInt8(0x00)
        
        XCTAssertThrowsError(try TransformLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))
        
    }
    
    /**
     Valid system numbers should be accepted.
    */
    func testValidSystemNumber() {
        
        let data = sampleLayerData()
        
        XCTAssertNoThrow(try TransformLayer.parse(fromData: data, moduleTypes: [], delegate: nil, delegateQueue: DispatchQueue.main))
        
    }
    
    /**
     General
    */
    
    func sampleLayerData() -> Data {
        var layer = TransformLayer.createAsData(withSystemNumber: 1, timestamp: 0, fullPointSet: true)
        layer.replacingPDULength(14, at: TransformLayer.Offset.length.rawValue)
        return layer
    }
    
    static var allTests = [
        ("testShortData", testShortData),
        ("testInvalidVector", testInvalidVector),
        ("testInvalidLength", testInvalidLength),
        ("testInvalidSystemNumber", testInvalidSystemNumber),
        ("testValidSystemNumber", testValidSystemNumber)
    ]

}

