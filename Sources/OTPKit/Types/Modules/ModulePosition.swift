//
//  ModulePosition.swift
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
 OTP Module Position
 
 Implements an OTP Standard Module of the Position type and handles creation and parsing.
 
 This data structure contains the current position of a Point in all three linear directions (x, y, z), and scaling indicating whether units are in μm or mm.

 Example usage:
 
 ``` swift

    // initialize a module at x = 0.002m, y = 1m, z = 2m
    let module = OTPModulePosition(x: 2000, y: 1000000, z: 2000000, scaling: .μm)
 
 ```

*/

public struct OTPModulePosition: OTPModule, Equatable {

    /// Uniquely identifies the module using an `OTPModuleIdentifier`.
    public static let identifier: OTPModuleIdentifier = OTPModuleIdentifier(manufacturerID: ModuleLayer.ManufacturerID.esta.rawValue, moduleNumber: ModuleLayer.StandardModuleNumber.position.rawValue)

    /// The size of the module's data in bytes.
    public static let dataLength: OTPPDULength = 13
    
    /// The total size of the module in bytes, including identifiers and length.
    public static let moduleLength: OTPPDULength = dataLength + OTPPDULength(ModuleLayer.Offset.data.rawValue)

    /**
     OTP Module Position Scaling Options
     
     Enumerates the possible scaling options for this module.
     
    */
    public enum Scaling: Int {
        
        /// Indicates the position values are in μm.
        case μm = 0
        
        /// Indicates the position values are in mm.
        case mm = 1
        
    }
    
    /**
     OTP Module Position Data Offsets

     Enumerates the data offset for each field in this layer.
     
    */
    private enum Offset: Int {
        case options = 0
        case x = 1
        case y = 5
        case z = 9
    }
    
    /**
     OTP Module Position Options Offsets
     
     Enumerates the bit offset for options flags.
     
    */
    private enum OptionsOffset: Int {
        case scaling = 7
    }
    
    /// The scaling of the position values in this module.
    public var scaling: Scaling = .μm
    
    /// The X position in units dependent on `scaling`.
    public var x: Int32 = 0 // μm or mm (scaling dependent)
    
    /// The Y position in units dependent on `scaling`.
    public var y: Int32 = 0 // μm or mm (scaling dependent)
    
    /// The Z position in units dependent on `scaling`.
    public var z: Int32 = 0 // μm or mm (scaling dependent)
    
    /// A human-readable log description of this module.
    public var logDescription: String {
        "\(moduleIdentifier.logDescription) position x:\(x), y:\(y), z:\(z) scaling: \(scaling)"
    }
    
    /**
     Initializes this `OTPModule` with default values.

    */
    public init() {
        // intializes the struct
    }
    
    /**
     Initializes an OTP Module Position.
     
     - Parameters:
        - x: The X position in units dependent on `scaling`.
        - y: The Y position in units dependent on `scaling`.
        - z: The Z position in units dependent on `scaling`.
        - scaling: The scaling of the position.
     
    */
    public init(x: Int32, y: Int32, z: Int32, scaling: Scaling) {
        self.x = x
        self.y = y
        self.z = z
        self.scaling = scaling
    }
    
    /**
     Creates a Module as Data.
     
     - Returns: The `OTPModule `as a `Data` object.

    */
    public func createAsData() -> Data {

        var data = Data()
                
        // scaling
        data.append(scaling == .μm ? 0b00000000 : 0b10000000)
        
        // x
        data.append(x.data)
        
        // y
        data.append(y.data)
        
        // z
        data.append(z.data)
        
        return data
        
    }
    
    /**
     Attempts to create an `OTPModulePosition` from the data.
     
     - Parameters:
        - data: The data to be parsed.
     
     - Throws: An error of type `ModuleLayerValidationError`.
     
     - Returns: A valid `OTPModulePosition` and the length of the PDU.
          
    */
    public static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength) {

        // there must be a complete layer
        guard data.count >= dataLength else { throw ModuleLayerValidationError.insufficientLength }
        
        // options
        guard let options = data.toUInt8(atOffset: Offset.options.rawValue)?.optionsFlags else { throw ModuleLayerValidationError.unableToParse(field: "Options", length: moduleLength) }
        
        // scaling
        guard let scaling = Scaling.init(rawValue: options[OptionsOffset.scaling.rawValue] ? 1 : 0) else { throw ModuleLayerValidationError.unableToParse(field: "Scaling", length: moduleLength) }
        
        // x
        guard let x = data.toInt32(atOffset: Offset.x.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Position X", length: moduleLength) }
        
        // y
        guard let y = data.toInt32(atOffset: Offset.y.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Position Y", length: moduleLength) }
        
        // z
        guard let z = data.toInt32(atOffset: Offset.z.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Position Z", length: moduleLength) }

        return (module: Self(x: x, y: y, z: z, scaling: scaling), length: moduleLength)
        
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

        // change the scaling of any μm modules to mm
        let scaledModules = theModules.map ({ module -> Self in
            
            switch module.scaling {
            case .mm:
                return module
            case .μm:
                return Self(x: module.x/1000, y:module.y/1000, z: module.z/1000, scaling: .mm)
            }
            
        })
        
        // get mean values
        let x = Math.mean(of: scaledModules.map { $0.x })
        let y = Math.mean(of: scaledModules.map { $0.y })
        let z = Math.mean(of: scaledModules.map { $0.z })
        
        return (module: Self(x: x, y: y, z: z, scaling: .mm), excludePoint: false)

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

    
}
