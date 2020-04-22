//
//  ModuleRotation.swift
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
 OTP Module Rotation
 
 Implements an OTP Standard Module of the Rotation type and handles creation and parsing.
 
 This data structure contains the current rotation of the Point using intrinsic Euler rotation calculated in the x-convention (the Tait-Bryan ZYX convention). Rotation is provided in millionths of a decimal degree i.e. 45,000,000 = 45° and shall be in the range 0-359999999 (0°-359.999999°).

 Example usage:
 
 ```

    // initialize a module at x = 45°, y = 0°, z = 45°
    let module = OTPModuleRotation(x: 45000000, y: 0, z: 45000000)
 
 ```

*/

public struct OTPModuleRotation: OTPModule, Equatable {

    /// Uniquely identifies the module using an `OTPModuleIdentifier`.
    public static let identifier: OTPModuleIdentifier = OTPModuleIdentifier(manufacturerID: ModuleLayer.ManufacturerID.esta.rawValue, moduleNumber: ModuleLayer.StandardModuleNumber.rotation.rawValue)

    /// The size of the module's data in bytes.
    public static let dataLength: OTPPDULength = 12
    
    /// The total size of the module in bytes, including identifiers and length.
    public static let moduleLength: OTPPDULength = dataLength + OTPPDULength(ModuleLayer.Offset.data.rawValue)
    
    /// The minimum permitted value for all variables in this module.
    public static let minPermitted: UInt32 = 0
    
    /// The maximum permitted value for all variables in this module.
    public static let maxPermitted: UInt32 = 359999999
    
    /// The modulo value to use for modified initialization values.
    private static let moduloValue = Self.maxPermitted + 1

    /**
     OTP Module Rotation Data Offsets

     Enumerates the data offset for each field in this layer.
     
    */
    private enum Offset: Int {
        case x = 0
        case y = 4
        case z = 8
    }
    
    /// The X rotation in millionths of a decimal degree i.e. 45,000,000 = 45°.
    public var x: UInt32 = 0
    
    /// The Y rotation in millionths of a decimal degree i.e. 45,000,000 = 45°.
    public var y: UInt32 = 0
    
    /// The Z rotation in millionths of a decimal degree i.e. 45,000,000 = 45°.
    public var z: UInt32 = 0
    
    /// A human-readable log description of this module.
    public var logDescription: String {
        "\(moduleIdentifier.logDescription) rotation x:\(x), y:\(y), z:\(z)"
    }
    
    /**
     Initializes this `OTPModule` with default values.

    */
    public init() {
        // intializes the struct
    }
    
    /**
     Initializes an OTP Module Rotation.
     
     If values outside of the permitted range are used (0-359,999,999), the remainder will be initialized, for example when initialized as 450,000,000 (450°), the resulting initialized value will be 90,000,000 (90°).
     
     - Parameters:
        - x: The X rotation in millionths of a decimal degree i.e. 45,000,000 = 45°.
        - y: The Y rotation in millionths of a decimal degree i.e. 45,000,000 = 45°.
        - z: The Z rotation in millionths of a decimal degree i.e. 45,000,000 = 45°.
     
    */
    public init(x: UInt32, y: UInt32, z: UInt32) {
        self.x = x % Self.moduloValue
        self.y = y % Self.moduloValue
        self.z = z % Self.moduloValue
    }
    
    /**
     Creates a Module as Data.
     
     - Returns: The `OTPModule `as a `Data` object.

    */
    public func createAsData() -> Data {

        var data = Data()

        // x
        data.append(min(x, Self.maxPermitted).data)
        
        // y
        data.append(min(y, Self.maxPermitted).data)
        
        // z
        data.append(min(z, Self.maxPermitted).data)
        
        return data
        
    }
    
    /**
     Attempts to create an `OTPModuleRotation` from the data.
     
     - Parameters:
        - data: The data to be parsed.
     
     - Throws: An error of type `ModuleLayerValidationError`.
     
     - Returns: A valid `OTPModuleRotation` and the length of the PDU.
          
    */
    public static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength) {

        // there must be a complete layer
        guard data.count >= dataLength else { throw ModuleLayerValidationError.insufficientLength }

        // x
        guard let x = data.toUInt32(atOffset: Offset.x.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Rotation X", length: moduleLength) }
        
        // Checkpoint: x rotation
        guard (minPermitted...maxPermitted).contains(x) else { throw ModuleLayerValidationError.invalidValue(field: "Rotation X", value: "\(x)", moduleIdentifier: Self.identifier, length: moduleLength)
        }
        
        // y
        guard let y = data.toUInt32(atOffset: Offset.y.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Rotation Y", length: moduleLength) }
        
        // Checkpoint: y rotation
        guard (minPermitted...maxPermitted).contains(y) else { throw ModuleLayerValidationError.invalidValue(field: "Rotation Y", value: "\(y)", moduleIdentifier: Self.identifier, length: moduleLength)
        }
        
        // z
        guard let z = data.toUInt32(atOffset: Offset.z.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Rotation Z", length: moduleLength) }
        
        // Checkpoint: z rotation
        guard (minPermitted...maxPermitted).contains(z) else { throw ModuleLayerValidationError.invalidValue(field: "Rotation Z", value: "\(z)", moduleIdentifier: Self.identifier, length: moduleLength)
        }
        
        return (module: Self(x: x, y: y, z: z), length: moduleLength)
        
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
        let x = Math.mean(of: theModules.map { $0.x })
        let y = Math.mean(of: theModules.map { $0.y })
        let z = Math.mean(of: theModules.map { $0.z })
        
        return (module: Self(x: x, y: y, z: z), excludePoint: false)
        
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
    public static func validValue(from string: String) -> UInt32 {
        
        // get a valid int from the string
        guard let intFromString = UInt32(exactly:(Double(string) ?? 0.0) * 1000000) else { return 0 }
        
        // the minimum allowed value
        return max(minPermitted, min(intFromString, maxPermitted))
        
    }
    
}
