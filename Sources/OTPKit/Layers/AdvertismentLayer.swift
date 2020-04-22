//
//  AdvertisementLayer.swift
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
 Advertisement Layer
 
 Implements the OTP Advertisement Layer and handles creation and parsing.

*/

struct AdvertismentLayer {
    
    /// The offset from which length counting begins.
    static let lengthCountOffset = Self.Offset.reserved.rawValue
    
    /**
     Advertisement Layer Vectors
     
     Enumerates the supported Vectors for this layer.
     
    */
    enum Vector: PDUVector {
        
        /// Contains a  `ModuleAdvertisementLayer`.
        case module = 0x0001
        
        /// Contains a  `NameAdvertisementLayer`.
        case name = 0x0002
        
        /// Contains an  `SystemAdvertisementLayer`.
        case system = 0x0003
        
    }
    
    /**
     Advertisement Layer Data Offsets

     Enumerates the data offset for each field in this layer.
     
    */
    enum Offset: Int {
        case vector = 0
        case length = 2
        case reserved = 4
        case data = 8
    }
    
    /// The vector describing the data in the layer.
    var vector: Vector
    
    /// The data contained in the layer.
    var data: Data
    
    /**
     Creates an Advertisement Layer as Data.
     
     - Parameters:
        - vector: The `Vector` of this layer.

     - Returns: An `AdvertisementLayer` as a `Data` object.

    */
    static func createAsData(with vector: Vector) -> Data {

        var data = Data()
        
        // the vector for this advertisement message
        data.append(vector.rawValue.data)

        // length of pdu [placeholder]
        data.append(contentsOf: [0x00, 0x00])
        
        // reserved
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        return data
        
    }
    
    /**
     Attempts to create an Advertisement Layer from the data.
     
     - Parameters:
        - data: The data to be parsed.
     
     - Throws: An error of type `AdvertisementLayerValidationError`.
     
     - Returns: A valid `AdvertisementLayer`.
          
    */
    static func parse(fromData data: Data) throws -> Self {

        // there must be a complete layer
        guard data.count >= Offset.data.rawValue else { throw AdvertisementLayerValidationError.insufficientLength }
        
        // the vector for this pdu
        guard let vector: PDUVector = data.toUInt16(atOffset: Offset.vector.rawValue) else { throw AdvertisementLayerValidationError.unableToParse(field: "Vector") }

        // Checkpoint: the vector must be supported
        guard let validVector = Vector.init(rawValue: vector) else { throw AdvertisementLayerValidationError.invalidVector(vector) }

        // length of pdu
        guard let length: OTPPDULength = data.toUInt16(atOffset: Offset.length.rawValue) else { throw AdvertisementLayerValidationError.unableToParse(field: "Length") }
        
        // Checkpoint: the pdu length field must match that of the data length after the length field
        guard length == data.count - Self.lengthCountOffset else { throw AdvertisementLayerValidationError.invalidLength }
        
        // reserved
        // ignore
        
        // layer data
        let data = data.subdata(in: Offset.data.rawValue..<data.count)
        
        return Self(vector: validVector, data: data)
        
    }
    
}

/**
 Advertisement Layer Validation Error
 
 Enumerates all possible `AdvertisementLayer` parsing errors.
 
*/

enum AdvertisementLayerValidationError: LocalizedError {

    /// The data is of insufficient length.
    case insufficientLength
    
    /// The length field does not match the actual data length.
    case invalidLength
    
    /// The `Vector` is not recognized.
    case invalidVector(_ vector: PDUVector)
    
    /// A field could not be parsed from the data.
    case unableToParse(field: String)

    /**
     A human-readable description of the error useful for logging purposes.
    */
    var logDescription: String {
        switch self {
        case .insufficientLength:
            return "Insufficient length for Advertisement Layer."
        case .invalidLength:
            return "Invalid Length in Advertisement Layer."
        case let .invalidVector(vector):
            return "Invalid Vector \(vector) in Advertisement Layer."
        case let .unableToParse(field):
            return "Unable to parse \(field) in Advertisement Layer."
        }
    }
        
}
