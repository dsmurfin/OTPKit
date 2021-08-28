//
//  TransformLayer.swift
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
 Transform Layer
 
 Implements the OTP Transform Layer and handles creation and parsing.

*/

struct TransformLayer {
    
    /// The offset from which length counting begins.
    static let lengthCountOffset = Self.Offset.systemNumber.rawValue
    
    /**
     Transform Layer Vectors
     
     Enumerates the supported Vectors for this layer.
     
    */
    enum Vector: PDUVector {
        
        /// Contains a  `PointLayer`.
        case point = 0x0001
        
    }
    
    /**
     Transform Layer Timing
     
     Enumerates the various timing intervals related to transform messages.
     
    */
    enum Timing: Milliseconds {
        
        /// The minimum interval between transmission of transform folios.
        case min = 1
        
        /// The maximum interval between transmission of transform folios.
        case max = 50
        
        /// The minimum interval between transmission of transform folios containing a full set of points.
        case fullPointSetMin = 2800
        
        /// The maximum interval between transmission of transform folios containing a full set of points.
        case fullPointSetMax = 3000
        
        /// The amount of time to wait after receiving the last transform message and entering a data loss state.
        case dataLossTimeout = 7500
        
    }

    /**
     Calculates the nearest valid transform interval to the one specified.
     
     - Parameters:
        - interval: The suggested interval to be validated.

     - Returns: A valid transform interval nearest to the value specified.
     
    */
    static func nearestValidTransformInterval(to interval: Milliseconds) -> Milliseconds {
        interval < Self.Timing.min.rawValue ? Self.Timing.min.rawValue : interval > Self.Timing.max.rawValue ? Self.Timing.max.rawValue : interval
    }
    
    /**
     Transform Layer Data Offsets

     Enumerates the data offset for each field in this layer.
     
    */
    enum Offset: Int {
        case vector = 0
        case length = 2
        case systemNumber = 4
        case timestamp = 5
        case options = 13
        case reserved = 14
        case data = 18
    }
    
    /**
     Transform Layer Options Offsets
     
     Enumerates the bit offset for options flags.
     
    */
    private enum OptionsOffset: Int {
        
        /// Whether this layer includes a full set of points.
        case fullPointSet = 7
        
    }
    
    /// The system number contained in the layer.
    var systemNumber: SystemNumber
    
    /// The number of milliseconds since the 'Time Origin' of the Producer that this transform layer was generated.
    var timestamp: Timestamp
    
    /// The valid `PointLayer`s contained in the layer.
    var points: [PointLayer]
    
    /// Whether this layer includes a full set of points.
    var fullPointSet: Bool
    
    /**
     Creates a Transform Layer as Data.
     
     - Parameters:
        - systemNumber: The `SystemNumber` of this Producer.
        - timestamp: The timestamp this message was generated.
        - fullPointSet: Whether this folio includes all points from this Producer.

     - Returns: A `TransformLayer` as a `Data` object.

    */
    static func createAsData(withSystemNumber systemNumber: SystemNumber, timestamp: Timestamp, fullPointSet: Bool) -> Data {

        var data = Data()
        
        // this vector for this message
        data.append(Vector.point.rawValue.data)
        
        // length of pdu [placeholder]
        data.append(contentsOf: [0x00, 0x00])
        
        // system number
        data.append(systemNumber.data)
        
        // timestamp
        data.append(timestamp.data)
        
        // options (full point set)
        data.append(fullPointSet ? 0b10000000 : 0b00000000)

        // reserved
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        return data
        
    }
    
    /**
     Attempts to create a Transform Layer from the data.
     
     - Parameters:
        - data: The data to be parsed.
        - moduleTypes: The modules implemented (either within the library or extras added).
        - delegate: An optional delegate to receive notifications.
        - delegateQueue: The dispatch queue on which to send delegate notifications.

     - Throws: An error of type `TransformLayerValidationError`
     
     - Returns: A valid `TransformLayer`.
          
    */
    static func parse(fromData data: Data, moduleTypes: [OTPModule.Type], delegate: OTPComponentProtocolErrorDelegate?, delegateQueue: DispatchQueue) throws -> Self {

        // there must be a complete layer
        guard data.count >= Offset.data.rawValue else { throw TransformLayerValidationError.insufficientLength }
        
        // the vector for this pdu
        guard let vector: PDUVector = data.toUInt16(atOffset: Offset.vector.rawValue) else { throw TransformLayerValidationError.unableToParse(field: "Vector") }
        
        // Checkpoint: the vector must be supported
        guard let _ = Vector.init(rawValue: vector) else { throw TransformLayerValidationError.invalidVector(vector) }

        // length of pdu
        guard let length: OTPPDULength = data.toUInt16(atOffset: Offset.length.rawValue) else { throw TransformLayerValidationError.unableToParse(field: "Length") }
        
        // Checkpoint: the pdu length field must match that of the data length after the length field
        guard length == data.count - Self.lengthCountOffset else { throw TransformLayerValidationError.invalidLength(length) }
        
        // system number
        guard let systemNumber: SystemNumber = data.toUInt8(atOffset: Offset.systemNumber.rawValue) else { throw TransformLayerValidationError.unableToParse(field: "System Number") }
        
        // Checkpoint: system number must be valid
        do {
            try systemNumber.validSystemNumber()
        } catch _ {
            throw TransformLayerValidationError.invalidSystemNumber(systemNumber)
        }
        
        // timestamp
        guard let timestamp: Timestamp = data.toUInt64(atOffset: Offset.timestamp.rawValue) else { throw TransformLayerValidationError.unableToParse(field: "Timestamp") }
        
        // options
        guard let options = data.toUInt8(atOffset: Offset.options.rawValue)?.optionsFlags else { throw TransformLayerValidationError.unableToParse(field: "Options") }
        
        // is this a full point set?
        let fullPointSet = options[OptionsOffset.fullPointSet.rawValue]

        // reserved
        // ignore
        
        // point data
        let pointData = data.subdata(in: Offset.data.rawValue..<data.count)
        
        var points = [PointLayer]()

        var offset = 0
        while offset < pointData.count {
            
            // remaining point data
            let data = pointData.subdata(in: offset..<pointData.count)

            do {
                
                // parse point layer
                let pointAndLength = try PointLayer.parse(fromData: data, moduleTypes: moduleTypes, delegate: delegate, delegateQueue: delegateQueue)

                // append this point
                points.append(pointAndLength.point)
                
                // increment offset by the point length
                offset += Int(pointAndLength.length)
                
            } catch let error as PointLayerValidationError {
                
                switch error {
                case .insufficientLength, .invalidLength:
                    
                    // notify the consumer of the error
                    delegateQueue.async { delegate?.layerError(error.logDescription) }
                    
                    // just return any points already parsed
                    return Self(systemNumber: systemNumber, timestamp: timestamp, points: points, fullPointSet: fullPointSet)
                    
                case let .invalidVector(_, pointLength):

                    // increment offset by the point length
                    offset += Int(pointLength)
                    
                case let .invalidPriority(_, pointLength):

                    // increment offset by the point length
                    offset += Int(pointLength)
                    
                case let .invalidPointNumber(_, pointLength):

                    // increment offset by the point length
                    offset += Int(pointLength)
                    
                case let .invalidGroupNumber(_, pointLength):

                    // increment offset by the point length
                    offset += Int(pointLength)
                    
                case let .unableToParse(_, pointLength):

                    if let length = pointLength {
                        
                        // increment offset by the point length
                        offset += Int(length)
                        
                    } else {

                        // notify the consumer of the error
                        delegateQueue.async { delegate?.layerError(error.logDescription) }

                        // just return any points already parsed
                        return Self(systemNumber: systemNumber, timestamp: timestamp, points: points, fullPointSet: fullPointSet)
                        
                    }
 
                }
                
                // notify the consumer of the error
                delegateQueue.async { delegate?.layerError(error.logDescription) }
                
            }
            
        }
        
        return Self(systemNumber: systemNumber, timestamp: timestamp, points: points, fullPointSet: fullPointSet)
        
    }

}

/**
 Transform Layer Validation Error
 
 Enumerates all possible `TransformLayer` parsing errors.
 
*/

enum TransformLayerValidationError: LocalizedError {
    
    /// The data is of insufficient length.
    case insufficientLength
    
    /// The length field does not match the actual data length.
    case invalidLength(_ length: OTPPDULength)
    
    /// The `Vector` is not recognized.
    case invalidVector(_ vector: PDUVector)
    
    /// The system number field contains an invalid system number.
    case invalidSystemNumber(_ number: SystemNumber)
    
    /// A field could not be parsed from the data.
    case unableToParse(field: String)

    /**
    A human-readable description of the error useful for logging purposes.
    */
    var logDescription: String {
        switch self {
        case .insufficientLength:
            return "Insufficient length for Transform Layer."
        case let .invalidLength(length):
            return "Invalid Length \(length) in Transform Layer."
        case let .invalidVector(vector):
            return "Invalid Vector \(vector) in Transform Layer."
        case let .invalidSystemNumber(systemNumber):
            return "Invalid System Number \(systemNumber) in Transform Layer."
        case let .unableToParse(field):
            return "Unable to parse \(field) in Transform Layer."
        }
    }
        
}
