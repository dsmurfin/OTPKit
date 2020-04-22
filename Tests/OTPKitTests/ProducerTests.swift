//
//  ProducerTests.swift
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

final class ProducerTests: XCTestCase {
    
    /**
     It should be possible to create a Producer with just a name, interface and delegate queue
    */
    func testCreateProducerWithName() {
        
        let componentName = ComponentName("TestName")
        
        let producer = OTPProducer(name: componentName, interface: "", delegateQueue: DispatchQueue.main)
        
        // the producer should have the name provided
        XCTAssertEqual(componentName, producer.name)
        
    }
    
    /**
     It should be possible to create a Producer with a name, CID, interface and delegate queue
    */
    func testCreateProducerWithCID() {
        
        let componentName = ComponentName("TestName")
        let cid = CID()

        let producer = OTPProducer(name: componentName, cid: cid, interface: "", delegateQueue: DispatchQueue.main)
        
        // the producer should have the cid provided
        XCTAssertEqual(cid, producer.cid)
        
    }
    
    /**
     It should be possible to add a Point with a valid Address to a Producer.
    */
    func testAddPoint() {

        let producer = sampleProducer()
        
        let validAddress = OTPAddress(system: 1, group: 1, point: 1)
        let invalidAddress = OTPAddress(system: 0, group: 1, point: 1)

        // should be able to add a point
        XCTAssertNoThrow(try producer.addPoint(with: validAddress))
        XCTAssertThrowsError(try producer.addPoint(with: invalidAddress))
        
        // should only be a single point
        XCTAssert(producer.numberOfPoints == 1)
        
    }
    
    /**
     It should be possible to add a Point with the same Address but a different Priority.
    */
    func testAddDuplicatePoint() {

        let producer = sampleProducer()
        
        let address = OTPAddress(system: 1, group: 1, point: 1)
        
        // should only be able to add this point once
        XCTAssertNoThrow(try producer.addPoint(with: address))
        XCTAssertThrowsError(try producer.addPoint(with: address))

        // should be able to add a point with the same address but higher priority once
        XCTAssertNoThrow(try producer.addPoint(with: address, priority: Priority.defaultPriority+1))
        XCTAssertThrowsError(try producer.addPoint(with: address, priority: Priority.defaultPriority+1))
        
        // should be 2 points
        XCTAssert(producer.numberOfPoints == 2)

    }
    
    /**
     It should be possible to remove Points either using Address only, or Address and Priority.
    */
    func testRemovePoint() {
        
        let producer = sampleProducer()
        
        let address = OTPAddress(system: 1, group: 1, point: 1)
        let address2 = OTPAddress(system: 1, group: 1, point: 2)
        let address3 = OTPAddress(system: 1, group: 1, point: 3)

        // should be able to add these point
        XCTAssertNoThrow(try producer.addPoint(with: address))
        XCTAssertNoThrow(try producer.addPoint(with: address, priority: Priority.defaultPriority+1))
        XCTAssertNoThrow(try producer.addPoint(with: address2))
        XCTAssertNoThrow(try producer.addPoint(with: address2, priority: Priority.defaultPriority+1))
        XCTAssertNoThrow(try producer.addPoint(with: address3))

        // should be 4 points
        XCTAssert(producer.numberOfPoints == 5)

        // should be able to remove these points
        XCTAssertNoThrow(try producer.removePoints(with: address))
        
        // should be 3 points
        XCTAssert(producer.numberOfPoints == 3)
        
        // should be able to remove this point
        XCTAssertNoThrow(try producer.removePoints(with: address2, priority: Priority.defaultPriority+1))
        
        // should be 2 points
        XCTAssert(producer.numberOfPoints == 2)
        
    }
    
    /**
     It should be possible to add a Module to a Point if the Point already exists.
    */
    func testAddModule() {

        let producer = sampleProducer()
        
        let addedAddress = OTPAddress(system: 1, group: 1, point: 1)
        let notAddedAddress = OTPAddress(system: 2, group: 1, point: 1)

        XCTAssertNoThrow(try producer.addPoint(with: addedAddress))

        let module = OTPModulePosition()

        XCTAssertNoThrow(try producer.addModule(module, toPoint: addedAddress))
        XCTAssertThrowsError(try producer.addModule(module, toPoint: notAddedAddress))

    }
    
    /**
     It should be possible to add a Module to a Point only if the Module doesn't already exist.
    */
    func testAddDuplicateModule() {
        
        let producer = sampleProducer()
        
        let address = OTPAddress(system: 1, group: 1, point: 1)
        let address2 = OTPAddress(system: 2, group: 1, point: 1)

        XCTAssertNoThrow(try producer.addPoint(with: address))
        XCTAssertNoThrow(try producer.addPoint(with: address, priority: 200))
        XCTAssertNoThrow(try producer.addPoint(with: address2, priority: 50))
        XCTAssertNoThrow(try producer.addPoint(with: address2, priority: 150))

        let module = OTPModulePosition()

        // should only be able to add this module once as the first should add to all priorities
        XCTAssertNoThrow(try producer.addModule(module, toPoint: address))
        XCTAssertThrowsError(try producer.addModule(module, toPoint: address, priority: 200))
        
        // should be possible to add the same module to a point with the same address but a different priority
        XCTAssertNoThrow(try producer.addModule(module, toPoint: address2, priority: 50))
        XCTAssertNoThrow(try producer.addModule(module, toPoint: address2, priority: 150))
        
    }
    
    /**
     General
    */
    
    func sampleProducer() -> OTPProducer {
        OTPProducer(name: "TestName", interface: "", delegateQueue: DispatchQueue.main)
    }

    static var allTests = [
        ("testCreateProducerWithName", testCreateProducerWithName),
        ("testCreateProducerWithCID", testCreateProducerWithCID),
        ("testAddPoint", testAddPoint),
        ("testAddDuplicatePoint", testAddDuplicatePoint),
        ("testRemovePoint", testRemovePoint),
        ("testAddModule", testAddModule),
        ("testAddDuplicateModule", testAddDuplicateModule)
    ]
    
}
