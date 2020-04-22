//
//  ModuleTests.swift
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
 Module Tests
*/

final class ModuleTests: XCTestCase {
    
    /**
     Creates a Module Parent.
    */
    func testCreateModuleParent() {
        
        let module1 = OTPModuleParent(systemNumber: 1, groupNumber: 2, pointNumber: 3)
        
        XCTAssertEqual(module1.systemNumber, 1)
        XCTAssertEqual(module1.groupNumber, 2)
        XCTAssertEqual(module1.pointNumber, 3)
        XCTAssertEqual(module1.relative, false)

        let module2 = OTPModuleParent(systemNumber: 4, groupNumber: 5, pointNumber: 6, relative: true)
        
        XCTAssertEqual(module2.systemNumber, 4)
        XCTAssertEqual(module2.groupNumber, 5)
        XCTAssertEqual(module2.pointNumber, 6)
        XCTAssertEqual(module2.relative, true)
        
        let module3 = OTPModuleParent(address: OTPAddress(system: 11, group: 12, point: 13))
        
        XCTAssertEqual(module3.systemNumber, 11)
        XCTAssertEqual(module3.groupNumber, 12)
        XCTAssertEqual(module3.pointNumber, 13)
        XCTAssertEqual(module3.relative, false)

        let module4 = OTPModuleParent(address: OTPAddress(system: 14, group: 15, point: 16), relative: true)
        
        XCTAssertEqual(module4.systemNumber, 14)
        XCTAssertEqual(module4.groupNumber, 15)
        XCTAssertEqual(module4.pointNumber, 16)
        XCTAssertEqual(module4.relative, true)
        
    }
    
    /**
     Creates a Module Position.
    */
    func testCreateModulePosition() {
        
        let module1 = OTPModulePosition()
        
        XCTAssertEqual(module1.scaling, OTPModulePosition.Scaling.μm)
        XCTAssertEqual(module1.x, 0)
        XCTAssertEqual(module1.y, 0)
        XCTAssertEqual(module1.z, 0)
        
    }
    
    /**
     Creates a Module Position Velocity Accel.
    */
    func testCreateModulePositionVelocityAccel() {
        
        let module1 = OTPModulePositionVelAccel()
        
        XCTAssertEqual(module1.aX, 0)
        XCTAssertEqual(module1.aY, 0)
        XCTAssertEqual(module1.aZ, 0)
        XCTAssertEqual(module1.vX, 0)
        XCTAssertEqual(module1.vY, 0)
        XCTAssertEqual(module1.vZ, 0)
        
    }
    
    /**
     Creates a Module Rotation.
    */
    func testCreateModuleRotation() {
        
        let module1 = OTPModuleRotation()
        
        XCTAssertEqual(module1.x, 0)
        XCTAssertEqual(module1.y, 0)
        XCTAssertEqual(module1.z, 0)
        
    }
    
    /**
     Creates a Module Rotation Velocity Accel.
    */
    func testCreateModuleRotationVelocityAccel() {
        
        let module1 = OTPModuleRotationVelAccel()
        
        XCTAssertEqual(module1.aX, 0)
        XCTAssertEqual(module1.aY, 0)
        XCTAssertEqual(module1.aZ, 0)
        XCTAssertEqual(module1.vX, 0)
        XCTAssertEqual(module1.vY, 0)
        XCTAssertEqual(module1.vZ, 0)
        
    }
    
    /**
     Creates a Module Scale.
    */
    func testCreateModuleScale() {
        
        let module1 = OTPModuleScale()
        
        XCTAssertEqual(module1.x, 1000000)
        XCTAssertEqual(module1.y, 1000000)
        XCTAssertEqual(module1.z, 1000000)
        
        let module2 = OTPModuleScale(x: 2000000)
        
        XCTAssertEqual(module2.x, 2000000)
        XCTAssertEqual(module2.y, 1000000)
        XCTAssertEqual(module2.z, 1000000)
        
        let module3 = OTPModuleScale(y: 2000000)
        
        XCTAssertEqual(module3.x, 1000000)
        XCTAssertEqual(module3.y, 2000000)
        XCTAssertEqual(module3.z, 1000000)
        
        let module4 = OTPModuleScale(z: 2000000)
        
        XCTAssertEqual(module4.x, 1000000)
        XCTAssertEqual(module4.y, 1000000)
        XCTAssertEqual(module4.z, 2000000)
        
    }
    
    /**
     Module Parent Equatable
    */
    func testEquatableModuleParent() {
        
        let module1 = OTPModuleParent(systemNumber: 1, groupNumber: 2, pointNumber: 3)
        let module2 = OTPModuleParent(systemNumber: 1, groupNumber: 2, pointNumber: 3)
        let module3 = OTPModuleParent(systemNumber: 1, groupNumber: 2, pointNumber: 4)

        XCTAssertEqual(module1, module2)
        XCTAssertNotEqual(module1, module3)

    }
    
    /**
     Module Position Equatable
    */
    func testEquatableModulePosition() {
        
        let module1 = OTPModulePosition(x: 10, y: 20, z: 30, scaling: .μm)
        let module2 = OTPModulePosition(x: 10, y: 20, z: 30, scaling: .μm)
        let module3 = OTPModulePosition(x: 10, y: 20, z: 30, scaling: .mm)
        
        XCTAssertEqual(module1, module2)
        XCTAssertNotEqual(module1, module3)

    }
    
    /**
     Module Position Velocity/Acceleration Equatable
    */
    func testEquatableModulePositionVelocityAccel() {
        
        let module1 = OTPModulePositionVelAccel(vX: 10, vY: 20, vZ: 30, aX: 10, aY: 20, aZ: 30)
        let module2 = OTPModulePositionVelAccel(vX: 10, vY: 20, vZ: 30, aX: 10, aY: 20, aZ: 30)
        let module3 = OTPModulePositionVelAccel(vX: 11, vY: 20, vZ: 30, aX: 10, aY: 20, aZ: 30)

        XCTAssertEqual(module1, module2)
        XCTAssertNotEqual(module1, module3)
        
    }
    
    /**
     Module Rotation Equatable
    */
    func testEquatableModuleRotation() {
        
        let module1 = OTPModuleRotation(x: 45, y: 90, z: 180)
        let module2 = OTPModuleRotation(x: 45, y: 90, z: 180)
        let module3 = OTPModuleRotation(x: 46, y: 90, z: 180)
        
        XCTAssertEqual(module1, module2)
        XCTAssertNotEqual(module1, module3)

    }
    
    /**
     Module Rotation Velocity/Acceleration Equatable
    */
    func testEquatableModuleRotationVelocityAccel() {
        
        let module1 = OTPModuleRotationVelAccel(vX: 10, vY: 20, vZ: 30, aX: 10, aY: 20, aZ: 30)
        let module2 = OTPModuleRotationVelAccel(vX: 10, vY: 20, vZ: 30, aX: 10, aY: 20, aZ: 30)
        let module3 = OTPModuleRotationVelAccel(vX: 11, vY: 20, vZ: 30, aX: 10, aY: 20, aZ: 30)

        XCTAssertEqual(module1, module2)
        XCTAssertNotEqual(module1, module3)
        
    }
    
    /**
     Module Scale Equatable
    */
    func testEquatableModuleScale() {
        
        let module1 = OTPModuleScale(x: 1000000, y: 1000000, z: 1000000)
        let module2 = OTPModuleScale(x: 1000000, y: 1000000, z: 1000000)
        let module3 = OTPModuleScale(x: 1000001, y: 1000000, z: 1000000)
        
        XCTAssertEqual(module1, module2)
        XCTAssertNotEqual(module1, module3)
        
    }
    
    static var allTests = [
        ("testCreateModuleParent", testCreateModuleParent),
        ("testCreateModulePosition", testCreateModulePosition),
        ("testCreateModulePositionVelocityAccel", testCreateModulePositionVelocityAccel),
        ("testCreateModuleRotation", testCreateModuleRotation),
        ("testCreateModuleRotationVelocityAccel", testCreateModuleRotationVelocityAccel),
        ("testCreateModuleScale", testCreateModuleScale),
        ("testEquatableModuleParent", testEquatableModuleParent),
        ("testEquatableModulePosition", testEquatableModulePosition),
        ("testEquatableModulePositionVelocityAccel", testEquatableModulePositionVelocityAccel),
        ("testEquatableModuleRotation", testEquatableModuleRotation),
        ("testEquatableModuleRotationVelocityAccel", testEquatableModuleRotationVelocityAccel),
        ("testEquatableModuleScale", testEquatableModuleScale)
    ]

}

