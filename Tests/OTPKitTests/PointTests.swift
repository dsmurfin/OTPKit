//
//  PointTests.swift
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
 Point Tests
*/

final class PointTests: XCTestCase {
    
    /**
     Invalid Priority should be rejected.
    */
    func testPriorityValidity() {
        
        let priorityInvalidHigh: Priority = 201
        let priorityValidLow: Priority = 0
        let priorityValidHigh: Priority = 200

        XCTAssertThrowsError(try priorityInvalidHigh.validPriority())
        XCTAssertNoThrow(try priorityValidLow.validPriority())
        XCTAssertNoThrow(try priorityValidHigh.validPriority())
        
    }
    
    /**
     It should be possible to create an OTP Point using an Address.
    */
    func testCreateWithAddress() {
        
        let validAddress = OTPAddress(system: 1, group: 1, point: 1)

        XCTAssertNoThrow(OTPPoint(address: validAddress, priority: 100))
        
        let validPoint = OTPPoint(address: validAddress, priority: 150)

        XCTAssertEqual(validPoint.address, OTPAddress(system: 1, group: 1, point: 1))
        XCTAssertEqual(validPoint.name, "")
        XCTAssertEqual(validPoint.priority, 150)

    }
    
    /**
     It should be possible to create an OTP Point using an Address and Point Name.
    */
    func testCreateWithAddressAndName() {
        
        let validAddress = OTPAddress(system: 1, group: 1, point: 1)

        XCTAssertNoThrow(OTPPoint(address: validAddress, priority: 100, name: "TestPoint1"))
        
        let validPoint = OTPPoint(address: validAddress, priority: 150, name: "TestPoint1")

        XCTAssertEqual(validPoint.address, OTPAddress(system: 1, group: 1, point: 1))
        XCTAssertEqual(validPoint.name, "TestPoint1")
        XCTAssertEqual(validPoint.priority, 150)

    }
    
    /**
     It should be possible to create an OTP Point using an Address and Priority and Point Name.
    */
    func testCreateWithAddressAndPriorityAndName() {
        
        let validAddress = OTPAddress(system: 1, group: 1, point: 1)

        XCTAssertNoThrow(OTPPoint(address: validAddress, priority: 40))
        XCTAssertNoThrow(OTPPoint(address: validAddress, priority: 50, name: "TestPoint"))

        let validPoint1 = OTPPoint(address: validAddress, priority: 40)
        let validPoint2 = OTPPoint(address: validAddress, priority: 50, name: "TestPoint")

        XCTAssertEqual(validPoint1.address, OTPAddress(system: 1, group: 1, point: 1))
        XCTAssertEqual(validPoint1.name, "")
        XCTAssertEqual(validPoint1.priority, 40)
        
        XCTAssertEqual(validPoint2.address, OTPAddress(system: 1, group: 1, point: 1))
        XCTAssertEqual(validPoint2.name, "TestPoint")
        XCTAssertEqual(validPoint2.priority, 50)

    }
    
    /**
     It should be possible to create an Producer Point.
    */
    func testCreateProducerPoint() {

        let address = OTPAddress(system: 1, group: 1, point: 1)
        
        let point = ProducerPoint(address: address, priority: 50, name: "TestPoint")
        
        XCTAssertEqual(point.address, OTPAddress(system: 1, group: 1, point: 1))
        XCTAssertEqual(point.priority, 50)
        XCTAssertEqual(point.name, "TestPoint")

        let nameData = "TestPoint".data(paddedTo: PointName.maxPointNameBytes)
        XCTAssertEqual(point.nameData, nameData)
        
        XCTAssert(point.modules.isEmpty)
        
    }
    
    /**
     It should be possible to rename a Producer Point.
    */
    func testRenameProducerPoint() {

        let address = OTPAddress(system: 1, group: 1, point: 1)
        
        var point = ProducerPoint(address: address, priority: 50, name: "TestPoint1")
        
        point.rename(name: "TestPoint2")
        
        XCTAssertEqual(point.name, "TestPoint2")

        let nameData = "TestPoint2".data(paddedTo: PointName.maxPointNameBytes)
        XCTAssertEqual(point.nameData, nameData)
        
    }
    
    /**
     It should be possible to add a module to a Producer Point.
    */
    func testProducerPointAddModule() {

        let address = OTPAddress(system: 1, group: 1, point: 1)
        
        var point = ProducerPoint(address: address, priority: 50, name: "TestPoint")
        
        XCTAssert(point.modules.isEmpty)
        
        let module = OTPModulePosition()

        XCTAssertNoThrow(try point.addModule(module, timeOrigin: Date()))
        
        XCTAssert(point.modules.count == 1)
        
        let module2 = OTPModuleRotationVelAccel()

        XCTAssertNoThrow(try point.addModule(module2, timeOrigin: Date()))
        
        XCTAssert(point.modules.count == 3)
                
    }
    
    /**
     It should be possible to remove a module from a Producer Point.
    */
    func testProducerPointRemoveModule() {
        
        let address = OTPAddress(system: 1, group: 1, point: 1)
        
        var point = ProducerPoint(address: address, priority: 50, name: "TestPoint")
        
        XCTAssert(point.modules.isEmpty)
        
        let module1 = OTPModulePosition()
        let module2 = OTPModuleScale()

        XCTAssertNoThrow(try point.addModule(module1, timeOrigin: Date()))
        XCTAssertNoThrow(try point.addModule(module2, timeOrigin: Date()))

        XCTAssert(point.modules.count == 2)
        
        XCTAssertNoThrow(try point.removeModule(with: module1.moduleIdentifier))

        XCTAssert(point.modules.count == 1)
        
        let module3 = OTPModuleRotationVelAccel()

        XCTAssertNoThrow(try point.addModule(module3, timeOrigin: Date()))
        
        XCTAssert(point.modules.count == 3)
        
        XCTAssertThrowsError(try point.removeModule(with: OTPModuleRotation.identifier))

    }
    
    /**
     It should be possible to update a module for a Producer Point.
    */
    func testProducerPointUpdateModule() {
        
        let address = OTPAddress(system: 1, group: 1, point: 1)
        
        var point = ProducerPoint(address: address, priority: 50, name: "TestPoint")
        
        XCTAssert(point.modules.isEmpty)
        
        let module = OTPModulePosition()

        XCTAssertNoThrow(try point.addModule(module, timeOrigin: Date()))

        XCTAssert(point.modules.count == 1)
        
        var moduleUpdated = OTPModulePosition()
        moduleUpdated.x = 100
        
        XCTAssertNoThrow(try point.update(module: moduleUpdated, timeOrigin: Date()))

        XCTAssert(point.modules.count == 1)
        
        let accessedModule = point.modules[0] as? OTPModulePosition
        
        XCTAssertNotNil(accessedModule)
        
        XCTAssertEqual(accessedModule!.x, 100)
        
    }
    
    /**
     It should be possible to create an Consumer Point.
    */
    func testCreateConsumerPoint() {

        let address = OTPAddress(system: 1, group: 1, point: 1)
        let cid = UUID()

        let point1 = ConsumerPoint(address: address, priority: 50, cid: cid, modules: [])
        let point2 = ConsumerPoint(address: address, priority: 150, name: "TestPoint", cid: cid, modules: [])
        
        XCTAssertEqual(point1.address, OTPAddress(system: 1, group: 1, point: 1))
        XCTAssertEqual(point1.priority, 50)
        XCTAssertEqual(point1.name, "")
        XCTAssertEqual(point1.cid, cid)
        
        XCTAssert(point1.modules.isEmpty)
        
        XCTAssertEqual(point2.address, OTPAddress(system: 1, group: 1, point: 1))
        XCTAssertEqual(point2.priority, 150)
        XCTAssertEqual(point2.name, "TestPoint")
        XCTAssertEqual(point2.cid, cid)
        
        XCTAssert(point2.modules.isEmpty)
        
    }
    
    /**
     It should be possible to rename a Consumer Point.
    */
    func testRenameConsumerPoint() {

        let address = OTPAddress(system: 1, group: 1, point: 1)
        let cid = UUID()
        
        var point = ConsumerPoint(address: address, priority: 50, cid: cid, modules: [])
        
        point.rename(name: "TestPoint2")
        
        XCTAssertEqual(point.name, "TestPoint2")

        let nameData = "TestPoint2".data(paddedTo: PointName.maxPointNameBytes)
        XCTAssertEqual(point.nameData, nameData)
        
    }
    
    /**
     Consumer Points should sort by Address, then by Priority (reversed, high first)
    */
    func testConsumerPointSort() {

        let cid = UUID()
        
        let point0 = ConsumerPoint(address: OTPAddress(system: 1, group: 1, point: 1), priority: 100, cid: cid, modules: [])
        let point1 = ConsumerPoint(address: OTPAddress(system: 1, group: 1, point: 1), priority: 50, cid: cid, modules: [])
        let point2 = ConsumerPoint(address: OTPAddress(system: 2, group: 1, point: 1), priority: 100, cid: cid, modules: [])
        let point3 = ConsumerPoint(address: OTPAddress(system: 2, group: 1, point: 1), priority: 50, cid: cid, modules: [])

        let points = [point2, point3, point0, point1].sorted()

        XCTAssertEqual(points[0], point0)
        XCTAssertEqual(points[1], point1)
        XCTAssertEqual(points[2], point2)
        XCTAssertEqual(points[3], point3)
        
    }
    
    static var allTests = [
        ("testPriorityValidity", testPriorityValidity),
        ("testCreateWithAddress", testCreateWithAddress),
        ("testCreateWithAddressAndName", testCreateWithAddressAndName),
        ("testCreateWithAddressAndPriorityAndName", testCreateWithAddressAndPriorityAndName),
        ("testCreateProducerPoint", testCreateProducerPoint),
        ("testRenameProducerPoint", testRenameProducerPoint),
        ("testProducerPointAddModule", testProducerPointAddModule),
        ("testProducerPointRemoveModule", testProducerPointRemoveModule),
        ("testProducerPointUpdateModule", testProducerPointUpdateModule),
        ("testCreateConsumerPoint", testCreateConsumerPoint),
        ("testRenameConsumerPoint", testRenameConsumerPoint),
        ("testConsumerPointSort", testConsumerPointSort)
    ]

}

