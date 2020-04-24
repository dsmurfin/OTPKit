//
//  ModuleScale.swift
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
 OTP Module Scale
 
 Implements an OTP Standard Module of the Scale type and handles creation and parsing.
 
 This data structure describes the unitless, absolute scale of the Point in the X, Y, and Z directions. The Scale Module may be used for description of Points that have the ability to change size.

 Example usage:
 
 ``` swift

    // initialize a module at x = actual size, y = actual size, z = half size
    let module = OTPModuleScale(x: 1000000, y: 1000000, z: 500000)
 
 ```

*/

public struct OTPModuleScale: OTPModule, Equatable {

    /// Uniquely identifies the module using an `OTPModuleIdentifier`.
    public static let identifier: OTPModuleIdentifier = OTPModuleIdentifier(manufacturerID: ModuleLayer.ManufacturerID.esta.rawValue, moduleNumber: ModuleLayer.StandardModuleNumber.scale.rawValue)

    /// The size of the module's data in bytes.
    public static let dataLength: OTPPDULength = 12
    
    /// The total size of the module in bytes, including identifiers and length.
    public static let moduleLength: OTPPDULength = dataLength + OTPPDULength(ModuleLayer.Offset.data.rawValue)

    /**
     OTP Module Scale Data Offsets
     
     Enumerates the data offset for each field in this layer.

    */
    private enum Offset: Int {
        case x = 0
        case y = 4
        case z = 8
    }
    
    /// The X scale in unitless millionths i.e 1,000,000 = reference size (x1), 500,000 = half reference size (0.5x).
    public var x: Int32 = 1000000
    
    /// The Y scale in unitless millionths i.e 1,000,000 = reference size (x1), 500,000 = half reference size (0.5x).
    public var y: Int32 = 1000000
    
    /// The Z scale in unitless millionths i.e 1,000,000 = reference size (x1), 500,000 = half reference size (0.5x).
    public var z: Int32 = 1000000
    
    /// A human-readable log description of this module.
    public var logDescription: String {
        "\(moduleIdentifier.logDescription) scale x:\(x), y:\(y), z:\(z)"
    }
    
    /**
     Initializes this `OTPModule` with default values.

    */
    public init() {
        // intialises the struct
    }
    
    /**
    Initializes an OTP Module Scale.
     
     - Parameters:
        - x: The scale of the x axis in unitless millionths i.e 1,000,000 = reference size (x1), 500,000 = half reference size (0.5x).
        - y: The scale of the y axis in unitless millionths i.e 1,000,000 = reference size (x1), 500,000 = half reference size (0.5x).
        - z: The scale of the z axis in unitless millionths i.e 1,000,000 = reference size (x1), 500,000 = half reference size (0.5x).
     
    */
    public init(x: Int32 = 1000000, y: Int32 = 1000000, z: Int32 = 1000000) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    /**
     Creates a Module as Data.
     
     - Returns: The `OTPModule `as a `Data` object.

    */
    public func createAsData() -> Data {

        var data = Data()

        // x
        data.append(x.data)
        
        // y
        data.append(y.data)
        
        // z
        data.append(z.data)
        
        return data
        
    }
    
    /**
     Attempts to create an `OTPModuleScale` from the data.
     
     - Parameters:
        - data: The data to be parsed.
     
     - Throws: An error of type `ModuleLayerValidationError`.
     
     - Returns: A valid `OTPModuleScale` and the length of the PDU.
          
    */
    public static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength) {

        // there must be a complete layer
        guard data.count >= dataLength else { throw ModuleLayerValidationError.insufficientLength }
        
        // x
        guard let x = data.toInt32(atOffset: Offset.x.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Scale X", length: moduleLength) }
        
        // y
        guard let y = data.toInt32(atOffset: Offset.y.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Scale Y", length: moduleLength) }
        
        // z
        guard let z = data.toInt32(atOffset: Offset.z.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Scale Z", length: moduleLength) }
        
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
    public static func validValue(from string: String) -> Int32 {
        
        // get a valid int from the string
        guard let intFromString = Int32(exactly:(Double(string) ?? 0.0) * 1000000) else { return 0 }
        
        // the valid value
        return intFromString
        
    }
    
}
