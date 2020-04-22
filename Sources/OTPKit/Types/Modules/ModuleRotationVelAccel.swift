//
//  ModuleRotationVelAccel.swift
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

import Foundation

/**
 OTP Module Rotation Velocity/Acceleration
 
 Implements an OTP Standard Module of the Rotation Velocity/Acceleration type and handles creation and parsing.
 
 This data structure contains the rotational velocity and acceleration of a Point. Velocity is provided in thousandths of a decimal degree/s, and Acceleration in thousandths of a decimal degree/s².
 
 This module supports velocities as low as 0.001 degrees/s and as high as 1000 revolutions/s. For example, a value of 45,000 for vX would mean a rotation of 45 degrees/s, or 0.125 revolutions/s, or 7.5 rpm.

 Example usage:
 
 ```

    // initialize a module at vX = 0°/s, vY = 0°/s, vZ = 15°/s and aX = 0°/s², aY = 0°/s², aZ = 5°/s²
    let module = OTPModuleRotationVelAccel(vX: 0, vY: 0, vZ: 15000, aX: 0, aY: 0, aZ: 5000)
 
 ```

*/

public struct OTPModuleRotationVelAccel: OTPModule, Equatable {
    
    /// Uniquely identifies the module using an `OTPModuleIdentifier`.
    public static let identifier: OTPModuleIdentifier = OTPModuleIdentifier(manufacturerID: ModuleLayer.ManufacturerID.esta.rawValue, moduleNumber: ModuleLayer.StandardModuleNumber.rotationVelocityAccel.rawValue)

    /// The size of the module's data in bytes.
    public static let dataLength: OTPPDULength = 24
    
    /// The total size of the module in bytes, including identifiers and length.
    public static let moduleLength: OTPPDULength = dataLength + OTPPDULength(ModuleLayer.Offset.data.rawValue)
    
    /// The minimum permitted value for all variables in this module.
    public static let minPermitted: Int32 = -360000000
    
    /// The maximum permitted value for all variables in this module.
    public static let maxPermitted: Int32 = 360000000

    /**
     OTP Module Rotation Velocity/Acceleration Data Offsets

     Enumerates the data offset for each field in this layer.
     
    */
    private enum Offset: Int {
        case vX = 0
        case vY = 4
        case vZ = 8
        case aX = 12
        case aY = 16
        case aZ = 20
    }
    
    /// The X rotation velocity in thousandths of a decimal degree/s i.e. 5,000 = 5°/s.
    public var vX: Int32 = 0
    
    /// The Y rotation velocity in thousandths of a decimal degree/s i.e. 5,000 = 5°/s.
    public var vY: Int32 = 0
    
    /// The Z rotation velocity in thousandths of a decimal degree/s i.e. 5,000 = 5°/s.
    public var vZ: Int32 = 0
    
    /// The X rotation acceleration in thousandths of a decimal degree/s² i.e. 5,000 = 5°/s².
    public var aX: Int32 = 0
    
    /// The Y rotation acceleration in thousandths of a decimal degree/s² i.e. 5,000 = 5°/s².
    public var aY: Int32 = 0
    
    /// The Z rotation acceleration in thousandths of a decimal degree/s² i.e. 5,000 = 5°/s².
    public var aZ: Int32 = 0
    
    /// A human-readable log description of this module.
    public var logDescription: String {
        "\(moduleIdentifier.logDescription) rotation vX:\(vX), vY:\(vY), vZ:\(vZ) aX:\(aX), aY:\(aY), aZ:\(aZ)"
    }

    /**
     Initializes this `OTPModule` with default values.

    */
    public init() {
        // intializes the struct
    }
    
    /**
     Initializes an OTP Module Rotation Velocity/Acceleration.
     
     - Parameters:
        - vX: The X rotation velocity in thousandths of a decimal degree/s i.e. 5,000 = 5°/s.
        - vY: The Y rotation velocity in thousandths of a decimal degree/s i.e. 5,000 = 5°/s.
        - vZ: The Z rotation velocity in thousandths of a decimal degree/s i.e. 5,000 = 5°/s.
        - aX: The X rotation acceleration in thousandths of a decimal degree/s² i.e. 5,000 = 5°/s².
        - aY: The Y rotation acceleration in thousandths of a decimal degree/s² i.e. 5,000 = 5°/s².
        - aZ: The Z rotation acceleration in thousandths of a decimal degree/s² i.e. 5,000 = 5°/s².
     
    */
    public init(vX: Int32, vY: Int32, vZ: Int32, aX: Int32, aY: Int32, aZ: Int32) {
        self.vX = max(min(vX, Self.maxPermitted), Self.minPermitted)
        self.vY = max(min(vY, Self.maxPermitted), Self.minPermitted)
        self.vZ = max(min(vZ, Self.maxPermitted), Self.minPermitted)
        self.aX = max(min(aX, Self.maxPermitted), Self.minPermitted)
        self.aY = max(min(aY, Self.maxPermitted), Self.minPermitted)
        self.aZ = max(min(aZ, Self.maxPermitted), Self.minPermitted)
    }
    
    /**
     Creates a Module as Data.
     
     - Returns: The `OTPModule `as a `Data` object.

    */
    public func createAsData() -> Data {

        var data = Data()

        // vX
        data.append(max(min(vX, Self.maxPermitted), Self.minPermitted).data)
        
        // vY
        data.append(max(min(vY, Self.maxPermitted), Self.minPermitted).data)
        
        // vZ
        data.append(max(min(vZ, Self.maxPermitted), Self.minPermitted).data)
        
        // aX
        data.append(max(min(aX, Self.maxPermitted), Self.minPermitted).data)
        
        // aY
        data.append(max(min(aY, Self.maxPermitted), Self.minPermitted).data)
        
        // aZ
        data.append(max(min(aZ, Self.maxPermitted), Self.minPermitted).data)
        
        return data
        
    }
    
    /**
     Attempts to create an `OTPModuleRotationVelocityAccel` from the data.
     
     - Parameters:
        - data: The data to be parsed.
     
     - Throws: An error of type `ModuleLayerValidationError`.
     
     - Returns: A valid `OTPModuleRotationVelocityAccel` and the length of the PDU.
          
    */
    public static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength) {

        // there must be a complete layer
        guard data.count >= dataLength else { throw ModuleLayerValidationError.insufficientLength }
        
        // vX
        guard let vX = data.toInt32(atOffset: Offset.vX.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Rotation Velocity X", length: moduleLength) }
        
        // Checkpoint: velocity x
        guard (minPermitted...maxPermitted).contains(vX) else { throw ModuleLayerValidationError.invalidValue(field: "Velocity X", value: "\(vX)", moduleIdentifier: Self.identifier, length: moduleLength)
        }
        
        // vY
        guard let vY = data.toInt32(atOffset: Offset.vY.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Rotation Velocity Y", length: moduleLength) }
        
        // Checkpoint: velocity y
        guard (minPermitted...maxPermitted).contains(vY) else { throw ModuleLayerValidationError.invalidValue(field: "Velocity Y", value: "\(vY)", moduleIdentifier: Self.identifier, length: moduleLength)
        }
        
        // vZ
        guard let vZ = data.toInt32(atOffset: Offset.vZ.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Rotation Velocity Z", length: moduleLength) }
        
        // Checkpoint: velocity z
        guard (minPermitted...maxPermitted).contains(vZ) else { throw ModuleLayerValidationError.invalidValue(field: "Velocity Z", value: "\(vZ)", moduleIdentifier: Self.identifier, length: moduleLength)
        }
        
        // aX
        guard let aX = data.toInt32(atOffset: Offset.vX.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Rotation Acceleration X", length: moduleLength) }
        
        // Checkpoint: acceleration x
        guard (minPermitted...maxPermitted).contains(aX) else { throw ModuleLayerValidationError.invalidValue(field: "Acceleration X", value: "\(aX)", moduleIdentifier: Self.identifier, length: moduleLength)
        }
        
        // aY
        guard let aY = data.toInt32(atOffset: Offset.vY.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Rotation Acceleration Y", length: moduleLength) }
        
        // Checkpoint: acceleration y
        guard (minPermitted...maxPermitted).contains(aY) else { throw ModuleLayerValidationError.invalidValue(field: "Acceleration Y", value: "\(aY)", moduleIdentifier: Self.identifier, length: moduleLength)
        }
        
        // aZ
        guard let aZ = data.toInt32(atOffset: Offset.vZ.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Rotation Acceleration Z", length: moduleLength) }
        
        // Checkpoint: acceleration z
        guard (minPermitted...maxPermitted).contains(aZ) else { throw ModuleLayerValidationError.invalidValue(field: "Acceleration Z", value: "\(aZ)", moduleIdentifier: Self.identifier, length: moduleLength)
        }
        
        return (module: Self(vX: vX, vY: vY, vZ: vZ, aX: aX, aY: aY, aZ: aZ), length: moduleLength)
        
    }
    
    /**
     Merges an arrray of modules.
     
     - Parameters:
        - modules: The `OTPModule`s to be merged.
     
     - Precondition: All modules must be of the same type.

     - Returns: An optional `OTPModule` of this type, and whether to exclude the `OTPPoint` due to a mismatch.

    */
    public static func merge(modules: [OTPModule]) -> (module: Self?, excludePoint: Bool) {
        
        // the modules must all be the same type
        guard let theModules = modules as? [Self] else { return (module: nil, excludePoint: false) }

        // get mean values
        let vX = Math.mean(of: theModules.map { $0.vX })
        let vY = Math.mean(of: theModules.map { $0.vY })
        let vZ = Math.mean(of: theModules.map { $0.vZ })
        let aX = Math.mean(of: theModules.map { $0.aX })
        let aY = Math.mean(of: theModules.map { $0.aY })
        let aZ = Math.mean(of: theModules.map { $0.aZ })
        
        return (module: Self(vX: vX, vY: vY, vZ: vZ, aX: aX, aY: aY, aZ: aZ), excludePoint: false)
        
    }
    
    /**
     Calculates whether this module is considered equal to another one.
     
     - Parameters:
        - module: The `OTPModule` to be compared against.
     
     - Precondition: Both modules must be of the same type.

     - Returns: Whether these `OTPModule`s are considered equal.

    */
    public func isEqualToModule(_ module: OTPModule) -> Bool {
        
        // the module must be of the same type
        guard let thisModule = module as? Self else { return false }
        
        // are these modules equal?
        return thisModule == self
        
    }
    
    /**
     Calculates a valid value for this fields in this module from the string provided.
     
     - Parameters:
        - string: The string to be evaluated.

     - Returns: A valid value for storing in this module.

    */
    public static func validValue(from string: String) -> Int32 {
        
        // get a valid int from the string
        guard let intFromString = Int32(exactly:(Double(string) ?? 0.0) * 1000) else { return 0 }
        
        // the minimum allowed value
        return max(minPermitted, min(intFromString, maxPermitted))
        
    }
    
}
