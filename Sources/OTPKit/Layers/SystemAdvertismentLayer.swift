//
//  SystemAdvertisementLayer.swift
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
 System Advertisement Layer
 
 Implements the OTP System Advertisement Layer and handles creation and parsing.

*/

struct SystemAdvertismentLayer {
    
    /// The offset from which length counting begins.
    static let lengthCountOffset = Self.Offset.options.rawValue
    
    /// The maximum number of `SystemNumber`s that can be included in a single message.
    static let maxMessageSystemNumbers = 200

    /**
     System Advertisement Layer Vectors
     
     Enumerates the supported Vectors for this layer.
     
    */
    enum Vector: PDUVector {
        
        /// Contains `SystemNumber`s being transmitted.
        case systemList = 0x0001
        
    }
    
    /**
     System Advertisment Layer Timing
     
     Enumerates the various timing intervals related to name advertisement.
     
    */
    enum Timing: Milliseconds {
        
        /// The maximum random amount of time to wait before replying to a request for system numbers.
        case maxBackoff = 5000
        
    }
    
    /**
     System Advertisement Layer Data Offsets

     Enumerates the data offset for each field in this layer.
     
    */
    enum Offset: Int {
        case vector = 0
        case length = 2
        case options = 4
        case reserved = 5
        case systemNumbers = 9
    }
    
    /**
     System Advertisement Layer Options Offsets
     
     Enumerates the bit offset for options flags.
     
    */
    private enum OptionsOffset: Int {

        /// Whether this is a request or a response
        case requestResponse = 7

    }

    /// The system numbers contained in the layer.
    var systemNumbers: [SystemNumber]?
    
    /**
     Creates a System Advertisement Layer as Data.
     
     - Parameters:
        - vector: The Vector of this layer.
        - systemNumbers: Optional: An array of `SystemNumber`s to include in this layer. `OTPConsumer`s should leave nil.

     - Returns: The `SystemAdvertisementLayer` as a `Data` object.

    */
    static func createAsData(with vector: Vector, systemNumbers: [SystemNumber] = []) -> Data {

        var data = Data()
        
        // the vector for this system advertisement message
        data.append(vector.rawValue.data)
        
        // length of pdu [placeholder]
        data.append(contentsOf: [0x00, 0x00])
        
        // options (request/response)
        data.append(systemNumbers.isEmpty ? 0b00000000 : 0b10000000)

        // reserved
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // the system numbers for this component (always a producer for responses)
        for systemNumber in systemNumbers {
            data.append(systemNumber.data)
        }
        
        return data
        
    }
    
    /**
     Attempts to create a System Advertisement Layer from the data.
     
     - Parameters:
        - data: The data to be parsed.
        - delegate: An optional delegate to receive notifications.
        - delegateQueue: The dispatch queue on which to send delegate notifications.

     - Throws: An error of type `SystemAdvertisementLayerValidationError`
     
     - Returns: An optional valid `SystemAdvertisementLayer`. `nil` indicates this is a request.

    */
    static func parse(fromData data: Data, delegate: OTPComponentProtocolErrorDelegate?, delegateQueue: DispatchQueue) throws -> Self? {
        
        // there must be a complete layer
        guard data.count >= Offset.systemNumbers.rawValue else { throw SystemAdvertisementLayerValidationError.insufficientLength }
        
        // the vector for this pdu
        guard let vector: PDUVector = data.toUInt16(atOffset: Offset.vector.rawValue) else { throw SystemAdvertisementLayerValidationError.unableToParse(field: "Vector") }
        
        // Checkpoint: the vector must be supported
        guard let _ = Vector.init(rawValue: vector) else { throw SystemAdvertisementLayerValidationError.invalidVector(vector) }

        // length of pdu
        guard let length: OTPPDULength = data.toUInt16(atOffset: Offset.length.rawValue) else { throw SystemAdvertisementLayerValidationError.unableToParse(field: "Length") }
        
        // Checkpoint: the pdu length field must match that of the data length after the length field
        guard length == data.count - Self.lengthCountOffset else { throw SystemAdvertisementLayerValidationError.invalidLength }
        
        // options
        guard let options = data.toUInt8(atOffset: Offset.options.rawValue)?.optionsFlags else { throw SystemAdvertisementLayerValidationError.unableToParse(field: "Options") }

        // reserved
        // ignore

        if !options[OptionsOffset.requestResponse.rawValue] {
            
            // request
            
            // returning nil indicates a request
            return nil
            
        } else {
            
            // response

            // system number data
            let systemNumberData = data.subdata(in: Offset.systemNumbers.rawValue..<data.count)
                        
            // the remaining data should be a multiple of system number's size containing at least 1 system number
            guard systemNumberData.count >= SystemNumber.sizeOfSystemNumber && systemNumberData.count.isMultiple(of: SystemNumber.sizeOfSystemNumber) else { throw SystemAdvertisementLayerValidationError.invalidSystemNumbers }
            
            // loop through all remaining data and get system numbers
            var systemNumbers = [SystemNumber]()
            for offset in stride(from: 0, to: systemNumberData.count, by: SystemNumber.sizeOfSystemNumber) {
                
                // try to get a system number and append it
                guard let systemNumber: SystemNumber = systemNumberData.toUInt8(atOffset: offset) else { continue }
                
                do {
                    
                    // the system number must be valid
                    try systemNumber.validSystemNumber()
                    
                    systemNumbers.append(systemNumber)
                    
                } catch let error as SystemAdvertisementLayerValidationError  {
                    
                    // notify the consumer of the error
                    delegateQueue.async { delegate?.layerError(error.logDescription) }

                }
                
            }

            return Self(systemNumbers: systemNumbers)
            
        }
        
    }
    
}

/**
 System Advertisement Layer Validation Error
 
 Enumerates all possible `SystemAdvertisementLayer` parsing errors.
 
*/

enum SystemAdvertisementLayerValidationError: LocalizedError {
    
    /// The data is of insufficient length.
    case insufficientLength
    
    /// The length field does not match the actual data length.
    case invalidLength
    
    /// The `Vector` is not recognized.
    case invalidVector(_ vector: PDUVector)
    
    /// The data is not a multiple of the size of an `SystemNumber`.
    case invalidSystemNumbers
    
    /// A particular `SystemNumber` is invalid.
    case invalidSystemNumber(_ number: SystemNumber)
    
    /// A field could not be parsed from the data.
    case unableToParse(field: String)

    /**
     A human-readable description of the error useful for logging purposes.
    */
    var logDescription: String {
        switch self {
        case .insufficientLength:
            return "Insufficient length for System Advertisement Layer."
        case .invalidLength:
            return "Invalid Length in System Advertisement Layer."
        case let .invalidVector(vector):
            return "Invalid Vector \(vector) in System Advertisement Layer."
        case .invalidSystemNumbers:
            return "Invalid List of System Numbers in System Advertisement Layer."
        case let .invalidSystemNumber(number):
            return "Invalid System Number \(number) in List of System Numbers in System Advertisement Layer."
        case let .unableToParse(field):
            return "Unable to parse \(field) in System Advertisement Layer."
        }
    }
        
}
