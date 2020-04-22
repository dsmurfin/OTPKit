//
//  ModuleLayer.swift
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
 Module Layer
 
 Implements the OTP Module Layer and handles creation and parsing.

*/

struct ModuleLayer {
    
    /// The offset from which length counting begins.
    static let lengthCountOffset = Self.Offset.moduleNumber.rawValue
    
    /**
     Module Layer Manufacturer IDs
     
     Enumerates the Manufacturer IDs directly implemented by the library.
     
    */
    enum ManufacturerID: OTPManufacturerID {
        
        /// Standard OTP ESTA module.
        case esta = 0x0000
        
    }
    
    /**
     Module Layer Standard Module Numbers
     
     Enumerates the Standard Module Numbers directly implemented by the library.
     
    */
    enum StandardModuleNumber: OTPModuleNumber {
        
        /// Standard positional data module.
        case position = 0x0001
        
        /// Standard positional velocity/acceleration data module.
        case positionVelocityAccel = 0x0002
        
        /// Standard rotation data module.
        case rotation = 0x0003
        
        /// Standard rotation velocity/acceleration data module.
        case rotationVelocityAccel = 0x0004
        
        /// Standard scale data module.
        case scale = 0x0005
        
        /// Standard parent data module.
        case parent = 0x0006
        
    }
    
    /**
     Module Layer Data Offsets
     
     Enumerates the data offset for each field in this layer.

    */
    enum Offset: Int {
        case manufacturerID = 0
        case length = 2
        case moduleNumber = 4
        case data = 6
    }
    
    /**
    Creates a Module Layer as Data.
     
     - Parameters:
        - module: The Module to be included in this Module Layer.

     - Returns: The `ModuleLayer` as a `Data` object.

    */
    static func createAsData(with module: OTPModule) -> Data {

        var data = Data()
        
        // this vector for this message
        data.append(module.moduleIdentifier.manufacturerID.data)
        
        // length of pdu [placeholder]
        data.append(contentsOf: [0x00, 0x00])
        
        // module number
        data.append(type(of: module).identifier.moduleNumber.data)

        // append the module data
        data.append(module.createAsData())
        
        // replace the length
        let moduleLayerLength: OTPPDULength = OTPPDULength(data.count - lengthCountOffset)
        data.replacingPDULength(moduleLayerLength, at: Offset.length.rawValue)
        
        return data
        
    }
    
    /**
    Attempts to create a Module Layer from the data.
     
     - Parameters:
        - data: The data to be parsed.
        - moduleTypes: The module types implemented (either within the library or extras added).
     
     - Throws: An error of type `ModuleLayerValidationError`
     
     - Returns: A valid `OTPModule` and the length of the PDU.
          
    */
    static func parse(fromData data: Data, moduleTypes: [OTPModule.Type]) throws -> (module: OTPModule, length: OTPPDULength) {

        // there must be a complete layer
        guard data.count >= Offset.data.rawValue else { throw ModuleLayerValidationError.insufficientLength }
        
        // the manufacturer id for this pdu
        guard let manufacturerID: OTPManufacturerID = data.toUInt16(atOffset: Offset.manufacturerID.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Manufacturer ID", length: nil) }

        // length of pdu
        guard let length: OTPPDULength = data.toUInt16(atOffset: Offset.length.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Length", length: nil) }
        
        // the module number for this pdu
        guard let moduleNumber: OTPModuleNumber = data.toUInt16(atOffset: Offset.moduleNumber.rawValue) else { throw ModuleLayerValidationError.unableToParse(field: "Module Number", length: length + OTPPDULength(lengthCountOffset)) }

        // Checkpoint: the pdu length field must be less than or equal to that of the data length after the length field
        guard length <= data.count - Self.lengthCountOffset else { throw ModuleLayerValidationError.invalidLength }
        
        // layer data
        let data = data.subdata(in: Offset.data.rawValue..<data.count)
        
        // attempt to get a module with this manufacturer and module number
        guard let moduleType = moduleTypes.first(where: { $0.identifier.manufacturerID == manufacturerID && $0.identifier.moduleNumber == moduleNumber }) else { throw ModuleLayerValidationError.unknownModule(manufacturerID: manufacturerID, moduleNumber: moduleNumber, length: length + OTPPDULength(lengthCountOffset)) }
        
        return try moduleType.parse(fromData: data)

    }
    
}

/**
 Module Layer Validation Error
 
 Enumerates all possible `ModuleLayer` parsing errors.
 
*/

enum ModuleLayerValidationError: LocalizedError {
    
    /// The data is of insufficient length.
    case insufficientLength
    
    /// The length field does not match the actual data length.
    case invalidLength
    
    /// The module is not recognized.
    case unknownModule(manufacturerID: OTPManufacturerID, moduleNumber: OTPModuleNumber, length: OTPPDULength)
    
    /// The module contains an invalid value for a certain field.
    case invalidValue(field: String, value: String, moduleIdentifier: OTPModuleIdentifier, length: OTPPDULength)
    
    /// A field could not be parsed from the data.
    case unableToParse(field: String, length: OTPPDULength?)

    /**
     A human-readable description of the error useful for logging purposes.
    */
    var logDescription: String {
        switch self {
        case .insufficientLength:
            return "Insufficient length for Module Layer."
        case .invalidLength:
            return "Invalid Length in Module Layer."
        case let .unknownModule(manufacturerID, moduleNumber, _):
            return "Unsupported Module [\(manufacturerID): \(moduleNumber)] in Module Layer."
        case let .invalidValue(field, value, moduleIdentifier, _):
            return "Invalid value \(value) for \(field) in Module [\(moduleIdentifier.manufacturerID): \(moduleIdentifier.moduleNumber)] in Module Layer."
        case let .unableToParse(field, _):
            return "Unable to parse \(field) in Module Layer."
        }
    }
        
}
