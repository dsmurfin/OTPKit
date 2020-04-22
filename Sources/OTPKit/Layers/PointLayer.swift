//
//  PointLayer.swift
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
 Point Layer
 
 Implements the OTP Point Layer and handles creation and parsing.

*/

struct PointLayer {
    
    /// The offset from which length counting begins.
    static let lengthCountOffset = Self.Offset.priority.rawValue
    
    /// The length of the module prior to any data (from where counting begins).
    static let lengthBeforeData = OTPPDULength(Self.Offset.data.rawValue - Self.lengthCountOffset)
    
    /// The offset at which the length field exists relative to the data field.
    static let lengthOffsetFromData = Self.Offset.data.rawValue - Self.Offset.length.rawValue

    /**
     Point Layer Vectors
     
     Enumerates the supported Vectors for this layer.
     
    */
    enum Vector: PDUVector {
        
        /// Contains `OTPModuleLayer`s.
        case module = 0x0001
        
    }
    
    /**
     Point Layer Data Offsets

     Enumerates the data offset for each field in this layer.
     
    */
    enum Offset: Int {
        case vector = 0
        case length = 2
        case priority = 4
        case groupNumber = 5
        case pointNumber = 7
        case timestamp = 11
        case options = 19
        case reserved = 20
        case data = 24
    }
    
    /// The priority of this Point.
    var priority: Priority
    
    /// The group number of this Point.
    var groupNumber: GroupNumber
    
    /// The point number of this Point.
    var pointNumber: PointNumber
    
    /// The number of milliseconds since the 'Time Origin' of the Producer that this Point was sampled.
    var timestamp: Timestamp
    
    /// The modules contained in the layer.
    var modules: [OTPModule]
    
    /**
    Creates a Point Layer as Data.
     
     - Parameters:
        - priority: The Priority for this Point.
        - groupNumber: The Group Number for this Point.
        - pointNumber: The Point Number for this Point.
        - timestamp: The number of milliseconds since the 'Time Origin' of the Producer that this Point was sampled.

     - Returns: A `PointLayer` as a `Data` object.

    */
    static func createAsData(withPriority priority: Priority, groupNumber: GroupNumber, pointNumber: PointNumber, timestamp: Timestamp) -> Data {

        var data = Data()
        
        // this vector for this message
        data.append(Vector.module.rawValue.data)
        
        // length of pdu [placeholder]
        data.append(contentsOf: [0x00, 0x00])
        
        // priority
        data.append(priority.data)
        
        // group number
        data.append(groupNumber.data)
        
        // point number
        data.append(pointNumber.data)
        
        // timestamp
        data.append(timestamp.data)
        
        // options
        data.append(0x00)

        // reserved
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        return data
        
    }
    
    /**
     Attempts to create a Point Layer from the data.
     
     - Parameters:
        - data: The data to be parsed.
        - moduleTypes: The modules implemented (either within the library or extras added).
        - delegate: An optional delegate to receive notifications.
        - delegateQueue: The dispatch queue on which to send delegate notifications.

     - Throws: An error of type `PointLayerValidationError`
     
     - Returns: A valid `PointLayer` and the length of the PDU.

    */
    static func parse(fromData data: Data, moduleTypes: [OTPModule.Type], delegate: OTPComponentProtocolErrorDelegate?, delegateQueue: DispatchQueue) throws -> (point: Self, length: OTPPDULength) {
        
        // there must be a complete layer
        guard data.count >= Offset.data.rawValue else { throw PointLayerValidationError.insufficientLength(OTPPDULength(data.count)) }
        
        // the vector for this pdu
        guard let vector: PDUVector = data.toUInt16(atOffset: Offset.vector.rawValue) else { throw PointLayerValidationError.unableToParse(field: "Vector", length: nil) }

        // length of pdu
        guard let length: OTPPDULength = data.toUInt16(atOffset: Offset.length.rawValue) else { throw PointLayerValidationError.unableToParse(field: "Length", length: nil) }
        
        // Checkpoint: the vector must be supported
        guard let _ = Vector.init(rawValue: vector) else { throw PointLayerValidationError.invalidVector(vector, length: length) }
        
        // Checkpoint: the pdu length field must be less than the remaining data and at least the start of the data for this module
        guard length <= data.count - Self.lengthCountOffset && length >= Offset.data.rawValue - Self.lengthCountOffset else { throw PointLayerValidationError.invalidLength(length) }

        // priority
        guard let priority: Priority = data.toUInt8(atOffset: Offset.priority.rawValue) else { throw PointLayerValidationError.unableToParse(field: "Priority", length: length) }
        
        // Checkpoint: priority must be valid
        do {
            try priority.validPriority()
        } catch _ {
            throw PointLayerValidationError.invalidPriority(priority, length: length)
        }
        
        // group number
        guard let groupNumber: GroupNumber = data.toUInt16(atOffset: Offset.groupNumber.rawValue) else { throw PointLayerValidationError.unableToParse(field: "Group Number", length: length) }
        
        // Checkpoint: group number must be valid
        do {
            try groupNumber.validGroupNumber()
        } catch _ {
            throw PointLayerValidationError.invalidGroupNumber(groupNumber, length: length)
        }

        // point number
        guard let pointNumber: PointNumber = data.toUInt32(atOffset: Offset.pointNumber.rawValue) else { throw PointLayerValidationError.unableToParse(field: "Point Number", length: length) }
        
        // Checkpoint: point number must be valid
        do {
            try pointNumber.validPointNumber()
        } catch _ {
            throw PointLayerValidationError.invalidPointNumber(pointNumber, length: length)
        }
        
        // timestamp
        guard let timestamp: Timestamp = data.toUInt64(atOffset: Offset.timestamp.rawValue) else { throw PointLayerValidationError.unableToParse(field: "Timestamp", length: length) }
        
        // options
        // ignore

        // reserved
        // ignore
        
        // module data
        let moduleData = data.subdata(in: Offset.data.rawValue..<lengthCountOffset+Int(length))

        var modules = [OTPModule]()

        var offset = 0
        while offset < moduleData.count {
            
            // remaining module data
            let data = moduleData.subdata(in: offset..<moduleData.count)

            do {
            
                // parse module layer
                let moduleAndLength = try ModuleLayer.parse(fromData: data, moduleTypes: moduleTypes)
                
                // append this module
                modules.append(moduleAndLength.module)
                
                // increment offset by the module length
                offset += Int(moduleAndLength.length)
                
            } catch let error as ModuleLayerValidationError {
                
                switch error {
                case .insufficientLength, .invalidLength:
                    
                    // notify the consumer of the error
                    delegateQueue.async { delegate?.layerError(error.logDescription) }
                    
                    // just return any modules already parsed
                    return (point: Self(priority: priority, groupNumber: groupNumber, pointNumber: pointNumber, timestamp: timestamp, modules: modules), length: length + OTPPDULength(lengthCountOffset))

                case let .unknownModule(_, _, moduleLength):

                    // increment offset by the module length
                    offset += Int(moduleLength)
                    
                case let .invalidValue(_, _, _, moduleLength):

                    // increment offset by the module length
                    offset += Int(moduleLength)
                    
                case let .unableToParse(_, moduleLength):

                    if let length = moduleLength {
                        
                        // increment offset by the module length
                        offset += Int(length)
                        
                    } else {
                        
                        // notify the consumer of the error
                        delegateQueue.async { delegate?.layerError(error.logDescription) }
                        
                        // just return any modules already parsed
                        return (point: Self(priority: priority, groupNumber: groupNumber, pointNumber: pointNumber, timestamp: timestamp, modules: modules), length: length + OTPPDULength(lengthCountOffset))
                        
                    }
                    
                }
                
                // notify the consumer of the error
                switch error {
                case .unknownModule:
                    // don't notify when the module is unknown
                    break
                default:
                    delegateQueue.async {  delegate?.layerError(error.logDescription) }
                }
                
            }
            
        }
        
        return (point: Self(priority: priority, groupNumber: groupNumber, pointNumber: pointNumber, timestamp: timestamp, modules: modules), length: length + OTPPDULength(lengthCountOffset))
        
    }
    
}

/**
 Point Layer Validation Error
 
 Enumerates all possible `PointLayer` parsing errors.
 
*/

enum PointLayerValidationError: LocalizedError {
    
    /// The data is of insufficient length.
    case insufficientLength(_ length: OTPPDULength)
    
    /// The length field does not match the actual data length.
    case invalidLength(_ length: OTPPDULength)
    
    /// The vector field is not recognized.
    case invalidVector(_ vector: PDUVector, length: OTPPDULength)
    
    /// The priority field contains an invalid priority.
    case invalidPriority(_ priority: Priority, length: OTPPDULength)
    
    /// The point number field contains an invalid point number.
    case invalidPointNumber(_ number: PointNumber, length: OTPPDULength)
    
    /// The group number field contains an invalid group number.
    case invalidGroupNumber(_ number: GroupNumber, length: OTPPDULength)
    
    /// A field could not be parsed from the data.
    case unableToParse(field: String, length: OTPPDULength?)

    /**
     A human-readable description of the error useful for logging purposes.
    */
    var logDescription: String {
        switch self {
        case let .insufficientLength(length):
            return "Insufficient length \(length) for Point Layer."
        case let .invalidLength(length):
            return "Invalid Length \(length) in Point Layer."
        case let .invalidVector(vector, _):
            return "Invalid Vector \(vector) in Point Layer."
        case let .invalidPriority(priority, _):
            return "Invalid Priority \(priority) in Point Layer."
        case let .invalidPointNumber(pointNumber, _):
            return "Invalid Point Number \(pointNumber) in Point Layer."
        case let .invalidGroupNumber(groupNumber, _):
            return "Invalid Group Number \(groupNumber) in Point Layer."
        case let .unableToParse(field, _):
            return "Unable to parse \(field) in Point Layer."
        }
    }
        
}
