//
//  ModuleAdvertisementLayer.swift
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
 Module Advertisement Layer
 
 Implements the OTP Module Advertisement Layer and handles creation and parsing.

*/

struct ModuleAdvertismentLayer {
    
    /// The offset from which length counting begins.
    static let lengthCountOffset = Self.Offset.reserved.rawValue
    
    /// The maximum number of `ModuleIdentifier`s that can be included in a single message.
    static let maxMessageModuleIdentifiers = 344
    
    /// The size in memory of a `ModuleIdentifier`.
    static let sizeOfModuleIdentifier = MemoryLayout<OTPManufacturerID>.size + MemoryLayout<OTPModuleNumber>.size

    /**
     Module Advertisement Layer Vectors
     
     Enumerates the supported Vectors for this layer.

    */
    enum Vector: PDUVector {
        
        /// Contains supported `OTPModuleIdentifier`s.
        case moduleList = 0x0001
        
    }
    
    /**
     Module Advertisment Layer Timing
     
     Enumerates the various timing intervals related to module advertisement.
     
    */
    enum Timing: Milliseconds {
        
        /// The interval between transmission of module advertisement folios.
        case interval = 10000
        
        /// The length of time to wait before starting transmission of transform messages (to allow for receiving of module advertisement messages).
        case startupWait = 12000
        
        /// The length of time to wait before ceasing transmission of modules no longer being advertised by any `OTPConsumer`s.
        case timeout = 30000
        
    }
    
    /**
     Module Advertisement Layer Data Offsets

     Enumerates the data offset for each field in this layer.
     
    */
    enum Offset: Int {
        case vector = 0
        case length = 2
        case reserved = 4
        case moduleIdentifiers = 8
    }

    /// The module identifiers contained in this layer.
    var moduleIdentifiers: [OTPModuleIdentifier]
    
    /**
    Creates a Module Advertisement Layer as Data.
     
     - Parameters:
        - vector: The `Vector` of this layer.
        - moduleIdentifiers: An Array of `OTPModuleIdentifier`s to include in this layer.

     - Returns: A `ModuleAdvertisementLayer` as a `Data` object.

    */
    static func createAsData(with vector: Vector, moduleIdentifiers: [OTPModuleIdentifier]) -> Data {

        var data = Data()
        
        // the vector for this module advertisement message
        data.append(vector.rawValue.data)
        
        // length of pdu [placeholder]
        data.append(contentsOf: [0x00, 0x00])

        // reserved
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // the module identifiers for this consumer
        for moduleIdentifier in moduleIdentifiers {
            data.append(moduleIdentifier.data)
        }
        
        return data
        
    }
    
    /**
    Attempts to create a Module Advertisement Layer from the data.
     
     - Parameters:
        - data: The data to be parsed.
     
     - Throws: An error of type `ModuleAdvertisementLayerValidationError`
     
     - Returns: A valid `ModuleAdvertisementLayer`.

    */
    static func parse(fromData data: Data) throws -> Self {
        
        // there must be a complete layer
        guard data.count >= Offset.moduleIdentifiers.rawValue else { throw ModuleAdvertisementLayerValidationError.insufficientLength }
        
        // the vector for this pdu
        guard let vector: PDUVector = data.toUInt16(atOffset: Offset.vector.rawValue) else { throw ModuleAdvertisementLayerValidationError.unableToParse(field: "Vector") }
        
        // Checkpoint: the vector must be supported
        guard let _ = Vector.init(rawValue: vector) else { throw ModuleAdvertisementLayerValidationError.invalidVector(vector) }

        // length of pdu
        guard let length: OTPPDULength = data.toUInt16(atOffset: Offset.length.rawValue) else { throw ModuleAdvertisementLayerValidationError.unableToParse(field: "Length") }
        
        // Checkpoint: the pdu length field must match that of the data length after the length field
        guard length == data.count - Self.lengthCountOffset else { throw ModuleAdvertisementLayerValidationError.invalidLength }
        
        // reserved
        // ignore
        
        // module identifier data
        let moduleIdentifierData = data.subdata(in: Offset.moduleIdentifiers.rawValue..<data.count)
        
        // the remaining data should be a multiple of module identifier's size containing at least 1 module identifier
        guard moduleIdentifierData.count >= sizeOfModuleIdentifier && moduleIdentifierData.count.isMultiple(of: sizeOfModuleIdentifier) else { throw ModuleAdvertisementLayerValidationError.invalidModuleIdentifiers }
        
        // loop through all remaining data and get module identifiers
        var moduleIdentifiers = [OTPModuleIdentifier]()
        for offset in stride(from: 0, to: moduleIdentifierData.count, by: sizeOfModuleIdentifier) {
            
            // try to get a module identifier and append it
            guard let moduleIdentifier = moduleIdentifierData.toModuleIdentifier(atOffset: offset) else { continue }
            moduleIdentifiers.append(moduleIdentifier)
            
        }
        
        return Self(moduleIdentifiers: moduleIdentifiers)
        
    }
    
}

/**
 Module Advertisement Layer Validation Error
 
 Enumerates all possible `ModuleAdvertisementLayer` parsing errors.
 
*/

enum ModuleAdvertisementLayerValidationError: LocalizedError {
    
    /// The data is of insufficient length.
    case insufficientLength
    
    /// The length field does not match the actual data length.
    case invalidLength
    
    /// The `Vector` is not recognized.
    case invalidVector(_ vector: PDUVector)
    
    /// The data is not a multiple of the size of a `OTPModuleIdentifier`.
    case invalidModuleIdentifiers
    
    /// A field could not be parsed from the data.
    case unableToParse(field: String)

    /**
     A human-readable description of the error useful for logging purposes.
    */
    var logDescription: String {
        switch self {
        case .insufficientLength:
            return "Insufficient length for Module Advertisement Layer."
        case .invalidLength:
            return "Invalid Length in Module Advertisement Layer."
        case let .invalidVector(vector):
            return "Invalid Vector \(vector) in Module Advertisement Layer."
        case .invalidModuleIdentifiers:
            return "Invalid List of Module Identifiers in Module Advertisement Layer."
        case let .unableToParse(field):
            return "Unable to parse \(field) in Module Advertisement Layer."
        }
    }
        
}
