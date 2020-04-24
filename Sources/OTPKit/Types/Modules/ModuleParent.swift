//
//  ModuleParent.swift
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
 OTP Module Parent
 
 Implements an OTP Standard Module of the Parent type and handles creation and parsing.
 
 This data structure contains the Address of the Parent of the Point and a flag which indicates whether other modules contained in this Point are relative to the Parent Point.
 
 Example usage:
 
 ``` swift

    do {
        
        let address = try OTPAddress(1,2,10)
 
        let module = OTPModuleParent(address: address, relative: false)
 
        // do something with module
 
    } catch {
        // handle error
    }
 
 ```

*/

public struct OTPModuleParent: OTPModule, Hashable {

    /// Uniquely identifies the module using an `OTPModuleIdentifier`.
    public static let identifier: OTPModuleIdentifier = OTPModuleIdentifier(manufacturerID: ModuleLayer.ManufacturerID.esta.rawValue, moduleNumber: ModuleLayer.StandardModuleNumber.parent.rawValue)

    /// The size of the module's data in bytes.
    public static let dataLength: OTPPDULength = 8
    
    /// The total size of the module in bytes, including identifiers and length.
    public static let moduleLength: OTPPDULength = dataLength + OTPPDULength(ModuleLayer.Offset.data.rawValue)

    /**
     OTP Module Parent Data Offsets

     Enumerates the data offset for each field in this layer.
     
    */
    private enum Offset: Int {
        case options = 0
        case systemNumber = 1
        case groupNumber = 2
        case pointNumber = 4
    }
    
    /**
     OTP Module Parent Options Offsets
     
     Enumerates the bit offset for options flags.
     
    */
    private enum OptionsOffset: Int {
        
        /// Whether the other `OTPModule`s contain relative values.
        case relative = 7
        
    }
    
    /// Whether the other `OTPModule`s contained within the same `OTPPoint` have values which are relative to the parent point.
    public var relative: Bool = false
    
    /// The `OTPSystemNumber ` of the parent of the `OTPPoint` containing this module.
    public var systemNumber: OTPSystemNumber = 1
    
    /// The `OTPGroupNumber ` of the parent of the `OTPPoint` containing this module.
    public var groupNumber: OTPGroupNumber = 1
    
    /// The `OTPPointNumber ` of the parent of the `OTPPoint` containing this module.
    public var pointNumber: OTPPointNumber = 1
    
    /// A human-readable log description of this module.
    public var logDescription: String {
        "\(moduleIdentifier.logDescription) address: \(systemNumber)/\(groupNumber)/\(pointNumber) relative: \(relative)"
    }
    
    /**
     Initializes this `OTPModule` with default values.

    */
    public init() {
        // intializes the struct
    }
    
    /**
     Initializes an OTP Module Parent.
     
     - Parameters:
        - systemNumber: The System Number of the Parent Point.
        - groupNumber: The Group Number of the Parent Point.
        - pointNumber: The Point Number of the Parent Point.
        - relative: Whether this Points other Modules contain values relative to the Parent Point.
     
     When using this internal initializer implementors must check the Address components are valid prior to initialization using `validSystemNumber()`, `validGroupNumber()` or `validPointNumber()`.
     
    */
    init(systemNumber: OTPSystemNumber, groupNumber: OTPGroupNumber, pointNumber: OTPPointNumber, relative: Bool = false) {
        self.relative = relative
        self.systemNumber = systemNumber
        self.groupNumber = groupNumber
        self.pointNumber = pointNumber
    }
    
    /**
     Initializes an OTP Module Parent.
     
     - Parameters:
        - address: The Address of the Parent Point.
        - relative: Whether this Points other Modules contain values relative to the Parent Point.
     
    */
    public init(address: OTPAddress, relative: Bool = false) {
        self.relative = relative
        self.systemNumber = address.systemNumber
        self.groupNumber = address.groupNumber
        self.pointNumber = address.pointNumber
    }
    
    /**
     Creates a Module as Data.
     
     - Returns: The `OTPModule `as a `Data` object.

    */
    public func createAsData() -> Data {

        var data = Data()
                
        // relative
        data.append(relative ? 0b10000000 : 0b00000000)
        
        // system number
        data.append(systemNumber.data)
        
        // group number
        data.append(groupNumber.data)
        
        // point number
        data.append(pointNumber.data)
        
        return data
        
    }
    
    /**
     Attempts to create an `OTPModuleParent` from the data.
     
     - Parameters:
        - data: The data to be parsed.
     
     - Throws: An error of type `ModuleLayerValidationError`.
     
     - Returns: A valid `OTPModuleParent` and the length of the PDU.
          
    */
    public static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength) {

        // there must be a complete layer
        guard data.count >= dataLength else { throw ModuleLayerValidationError.insufficientLength }
        
        // options
        guard let relative = data.toUInt8(atOffset: Offset.options.rawValue)?.optionsFlags[OptionsOffset.relative.rawValue] else { throw ModuleLayerValidationError.unableToParse(field: "Options", length: moduleLength) }

        // system number
        guard let systemNumber: SystemNumber = data.toUInt8(atOffset: Offset.systemNumber.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "System Number", length: moduleLength) }
        
        // Checkpoint: system number must be valid
        do {
            try systemNumber.validSystemNumber()
        } catch _ {
            throw ModuleLayerValidationError.invalidValue(field: "System Number", value: "\(systemNumber)", moduleIdentifier: Self.identifier, length: moduleLength)
        }
        
        // group number
        guard let groupNumber: GroupNumber = data.toUInt16(atOffset: Offset.groupNumber.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Group Number", length: moduleLength) }
        
        // Checkpoint: group number must be valid
        do {
            try groupNumber.validGroupNumber()
        } catch _ {
            throw ModuleLayerValidationError.invalidValue(field: "Group Number", value: "\(groupNumber)", moduleIdentifier: Self.identifier, length: moduleLength)
        }
        
        // point number
        guard let pointNumber: PointNumber = data.toUInt32(atOffset: Offset.pointNumber.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Point Number", length: moduleLength) }
        
        // Checkpoint: point number must be valid
        do {
            try pointNumber.validPointNumber()
        } catch _ {
            throw ModuleLayerValidationError.invalidValue(field: "Point Number", value: "\(pointNumber)", moduleIdentifier: Self.identifier, length: moduleLength)
        }
        
        return (module: Self(systemNumber: systemNumber, groupNumber: groupNumber, pointNumber: pointNumber, relative: relative), length: moduleLength)
        
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

        if Set(theModules).count == 1 {
            
            // all modules are equal
            return (module: theModules.first, excludePoint: false)
            
        } else if theModules.contains(where: { $0.relative }) {
            
            // the modules are not the same, and some say this point should be relative
            // no sensible information can be derived for this point, so exclude it
            return (module: nil, excludePoint: true)
            
        }
        
        // the parent isn't being used for relative values, so exclude this module
        return (module: nil, excludePoint: false)

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
