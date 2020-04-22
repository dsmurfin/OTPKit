//
//  ModulePositionVelAccel.swift
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
 OTP Module Position Velocity/Acceleration
 
 Implements an OTP Standard Module of the Position Velocity/Acceleration type and handles creation and parsing.
 
 This data structure contains the positional velocity and acceleration of a Point. Velocity is provided in μm/s, and Acceleration in μm/s².

 Example usage:
 
 ```

    // initialize a module at vX = 0.5m/s, vY = 0m/s, vZ = 0m/s and aX = 0.05m/s², aY = 0m/s², aZ = 0m/s²
    let module = OTPModulePositionVelAccel(vX: 500000, vY: 0, vZ: 0, aX: 50000, aY: 0, aZ: 0)
 
 ```

*/

public struct OTPModulePositionVelAccel: OTPModule, Equatable {
    
    /// Uniquely identifies the module using an `OTPModuleIdentifier`.
    public static let identifier: OTPModuleIdentifier = OTPModuleIdentifier(manufacturerID: ModuleLayer.ManufacturerID.esta.rawValue, moduleNumber: ModuleLayer.StandardModuleNumber.positionVelocityAccel.rawValue)

    /// The size of the module's data in bytes.
    public static let dataLength: OTPPDULength = 24
    
    /// The total size of the module in bytes, including identifiers and length.
    public static let moduleLength: OTPPDULength = dataLength + OTPPDULength(ModuleLayer.Offset.data.rawValue)

    /**
     OTP Module Position Velocity/Acceleration Data Offsets

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
    
    /// The X position velocity in μm/s.
    public var vX: Int32 = 0
    
    /// The Y position velocity in μm/s.
    public var vY: Int32 = 0
    
    /// The Z position velocity in μm/s.
    public var vZ: Int32 = 0
    
    /// The X position acceleration in μm/s².
    public var aX: Int32 = 0
    
    /// The Y position acceleration in μm/s².
    public var aY: Int32 = 0
    
    /// The Z position acceleration in μm/s².
    public var aZ: Int32 = 0
    
    /// A human-readable log description of this module.
    public var logDescription: String {
        "\(moduleIdentifier.logDescription) position vX:\(vX), vY:\(vY), vZ:\(vZ) aX:\(aX), aY:\(aY), aZ:\(aZ)"
    }
    
    /**
     Initializes this `OTPModule` with default values.

    */
    public init() {
        // intializes the struct
    }
    
    /**
     Initializes an OTP Module Position Velocity/Acceleration.
     
     - Parameters:
        - vX: The X position velocity in μm/s.
        - vY: The Y position velocity in μm/s.
        - vZ: The Z position velocity in μm/s.
        - aX: The X position acceleration in μm/s².
        - aY: The Y position acceleration in μm/s².
        - aZ: The Z position acceleration in μm/s².
     
    */
    public init(vX: Int32, vY: Int32, vZ: Int32, aX: Int32, aY: Int32, aZ: Int32) {
        self.vX = vX
        self.vY = vY
        self.vZ = vZ
        self.aX = aX
        self.aY = aY
        self.aZ = aZ
    }
    
    /**
     Creates a Module as Data.
     
     - Returns: The `OTPModule `as a `Data` object.

    */
    public func createAsData() -> Data {

        var data = Data()

        // vX
        data.append(vX.data)
        
        // vY
        data.append(vY.data)
        
        // vZ
        data.append(vZ.data)
        
        // aX
        data.append(aX.data)
        
        // aY
        data.append(aY.data)
        
        // aZ
        data.append(aZ.data)
        
        return data
        
    }
    
    /**
     Attempts to create an `OTPModulePositionVelocityAccel` from the data.
     
     - Parameters:
        - data: The data to be parsed.
     
     - Throws: An error of type `ModuleLayerValidationError`.
     
     - Returns: A valid `OTPModulePositionVelocityAccel` and the length of the PDU.
          
    */
    public static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength) {

        // there must be a complete layer
        guard data.count >= dataLength else { throw ModuleLayerValidationError.insufficientLength }
        
        // vX
        guard let vX = data.toInt32(atOffset: Offset.vX.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Position Velocity X", length: moduleLength) }
        
        // vY
        guard let vY = data.toInt32(atOffset: Offset.vY.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Position Velocity Y", length: moduleLength) }
        
        // vZ
        guard let vZ = data.toInt32(atOffset: Offset.vZ.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Position Velocity Z", length: moduleLength) }
        
        // aX
        guard let aX = data.toInt32(atOffset: Offset.vX.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Position Acceleration X", length: moduleLength) }
        
        // aY
        guard let aY = data.toInt32(atOffset: Offset.vY.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Position Acceleration Y", length: moduleLength) }
        
        // aZ
        guard let aZ = data.toInt32(atOffset: Offset.vZ.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Position Acceleration Z", length: moduleLength) }
        
        return (module: Self(vX: vX, vY: vY, vZ: vZ, aX: aX, aY: aY, aZ: aZ), length: moduleLength)
        
    }
    
    /**
    Merges an arrray of modules.
     
     - Parameters:
        - modules: The `OTPModule`s to be merged.

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
    Compares these modules for equality.
     
     - Parameters:
        - module: The module to compare against.

     - Returns: Whether these modules are equal.
          
    */
    public func isEqualToModule(_ module: OTPModule) -> Bool {
        
        // the module must be of the same type
        guard let thisModule = module as? Self else { return false }
        
        // are these modules equal?
        return thisModule == self
        
    }

    
}
