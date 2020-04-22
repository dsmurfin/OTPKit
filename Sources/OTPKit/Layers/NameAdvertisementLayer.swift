//
//  NameAdvertisementLayer.swift
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
 Name Advertisement Layer
 
 Implements the OTP Name Advertisement Layer and handles creation and parsing.

*/

struct NameAdvertismentLayer {
    
    /// The offset from which length counting begins.
    static let lengthCountOffset = Self.Offset.options.rawValue
    
    /// The maximum number of `AddressPointDescription`s that can be included in a single message.
    static let maxMessageAddressPointDescriptions = 35
    
    /// The size in memory of a `AddressPointDescription`.
    static let sizeOfAddressPointDescription = MemoryLayout<SystemNumber>.size + MemoryLayout<GroupNumber>.size + MemoryLayout<PointNumber>.size + PointName.maxPointNameBytes
    
    /**
     Name Advertisement Layer Vectors
     
     Enumerates the supported Vectors for this layer.
     
    */
    enum Vector: PDUVector {
        
        /// Contains `AddressPointDescription`s for some or all transmitted points.
        case nameList = 0x0001
        
    }
    
    /**
     Name Advertisment Layer Timing
     
     Enumerates the various timing intervals related to name advertisement.
     
    */
    enum Timing: Milliseconds {
        
        /// The maximum random amount of time to wait before replying to a request for names.
        case maxBackoff = 5000
        
    }
    
    /**
     Name Advertisement Layer Data Offsets

     Enumerates the data offset for each field in this layer.
     
    */
    enum Offset: Int {
        case vector = 0
        case length = 2
        case options = 4
        case reserved = 5
        case addressPointDescriptions = 9
    }
    
    /**
     Name Advertisement Layer Options Offsets
     
     Enumerates the bit offset for options flags.
     
    */
    private enum OptionsOffset: Int {
        
        /// Whether this is a request or a response
        case requestResponse = 7
        
    }
    
    /// The address point descriptions contained in the layer.
    var addressPointDescriptions: [AddressPointDescription]?
    
    /**
    Creates a Name Advertisement Layer as Data.
     
     - Parameters:
        - vector: The Vector of this layer.
        - addressPointDescriptions: Optional: An array of `AddressPointDescription`s to include in this layer. `OTPConsumer`s should leave nil.

     - Returns: A `NameAdvertisementLayer` as a `Data` object.

    */
    static func createAsData(with vector: Vector, addressPointDescriptions: [AddressPointDescription] = []) -> Data {

        var data = Data()
        
        // the vector for this name advertisement message
        data.append(vector.rawValue.data)
        
        // length of pdu [placeholder]
        data.append(contentsOf: [0x00, 0x00])
        
        // options (request/response)
        data.append(addressPointDescriptions.isEmpty ? 0b00000000 : 0b10000000)

        // reserved
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // the address point descriptions for this component (always a producer for responses)
        for addressPointDescription in addressPointDescriptions {
            data.append(addressPointDescription.data)
        }
        
        return data
        
    }
    
    /**
    Attempts to create a Name Advertisement Layer from the data.
     
     - Parameters:
        - data: The data to be parsed.
     
     - Throws: An error of type `NameAdvertisementLayerValidationError`
     
     - Returns: An optional valid `NameAdvertisementLayer`. `nil` indicates this is a request.
          
    */
    static func parse(fromData data: Data) throws -> Self? {
        
        // there must be a complete layer
        guard data.count >= Offset.addressPointDescriptions.rawValue else { throw NameAdvertisementLayerValidationError.insufficientLength }
        
        // the vector for this pdu
        guard let vector: PDUVector = data.toUInt16(atOffset: Offset.vector.rawValue) else { throw NameAdvertisementLayerValidationError.unableToParse(field: "Vector") }
        
        // Checkpoint: the vector must be supported
        guard let _ = Vector.init(rawValue: vector) else { throw NameAdvertisementLayerValidationError.invalidVector(vector) }

        // length of pdu
        guard let length: OTPPDULength = data.toUInt16(atOffset: Offset.length.rawValue) else { throw NameAdvertisementLayerValidationError.unableToParse(field: "Length") }
        
        // Checkpoint: the pdu length field must match that of the data length after the length field
        guard length == data.count - Self.lengthCountOffset else { throw NameAdvertisementLayerValidationError.invalidLength }
        
        // options
        guard let options = data.toUInt8(atOffset: Offset.options.rawValue)?.optionsFlags else { throw NameAdvertisementLayerValidationError.unableToParse(field: "Options") }
        
        // reserved
        // ignore
        
        // options
        if !options[OptionsOffset.requestResponse.rawValue] {
            
            // request
            
            // returning nil indicates a request
            return nil
            
        } else {
            
            // response
            
            // address point description data
            let addressPointDescriptionData = data.subdata(in: Offset.addressPointDescriptions.rawValue..<data.count)
                        
            // the remaining data should be a multiple of address point description's size containing at least 1 address point descipription
            guard addressPointDescriptionData.count >= sizeOfAddressPointDescription && addressPointDescriptionData.count.isMultiple(of: sizeOfAddressPointDescription) else { throw NameAdvertisementLayerValidationError.invalidAddressPointDescriptions }
            
            // loop through all remaining data and get address point descriptions
            var addressPointDescriptions = [AddressPointDescription]()
            for offset in stride(from: 0, to: addressPointDescriptionData.count, by: sizeOfAddressPointDescription) {
                
                // try to get an address point description and append it
                guard let addressPointDescription = addressPointDescriptionData.toAddressPointDescription(atOffset: offset) else { continue }
                addressPointDescriptions.append(addressPointDescription)
                
            }
            
            return Self(addressPointDescriptions: addressPointDescriptions)
            
        }
        
    }
    
}

/**
 Name Advertisement Layer Validation Error
 
 Enumerates all possible `NameAdvertisementLayer` parsing errors.
 
*/

enum NameAdvertisementLayerValidationError: LocalizedError {
    
    /// The data is of insufficient length.
    case insufficientLength
    
    /// The length field does not match the actual data length.
    case invalidLength
    
    /// The `Vector` is not recognized.
    case invalidVector(_ vector: PDUVector)
    
    /// The data is not a multiple of the size of an `AddressPointDescription`.
    case invalidAddressPointDescriptions
    
    /// A field could not be parsed from the data.
    case unableToParse(field: String)

    /**
    A human-readable description of the error useful for logging purposes.
    */
    var logDescription: String {
        switch self {
        case .insufficientLength:
            return "Insufficient length for Name Advertisement Layer."
        case .invalidLength:
            return "Invalid Length in Name Advertisement Layer."
        case let .invalidVector(vector):
            return "Invalid Vector \(vector) in Name Advertisement Layer."
        case .invalidAddressPointDescriptions:
            return "Invalid List of Address Point Descriptions in Name Advertisement Layer."
        case let .unableToParse(field):
            return "Unable to parse \(field) in Name Advertisement Layer."
        }
    }
        
}

