//
//  OTPLayer.swift
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

/// A type used for the length of protocol data units (PDUs) in all OTP layers.
public typealias OTPPDULength = UInt16

/// A type used to identify the protocol data unit's (PDU's) data in all OTP layers.
typealias PDUVector = UInt16

/// A type used for the footer length in the `OTPLayer`
typealias FooterLength = UInt8

/// A type used for page and last page fields in the `OTPLayer`.
typealias Page = UInt16

/// A type used in the `OTPLayer` to identify messages which together make up a snapshot of information, which due to its size has to be split across multiple messages.
typealias FolioNumber = UInt32

/**
 Folio Number Extension
 
 Extensions to `FolioNumber`.

*/

extension FolioNumber {

    /**
    Compares this Folio Number with a previous one to determine whether it is considered 'part of the current communication'.
     
     - Parameters:
        - previousFolio: The previous folio number.
        - window: The window of older folio numbers to allow. If not provided the window will be 0 which no older folios will be allowed.

     - Returns: Whether this is considered 'part of the current communication' (in sequence).

    */
    func isPartOfCurrentCommunication(previous previousFolio: FolioNumber, window: FolioNumber = 0) -> Bool {
        !(0...65535).contains((previousFolio &- window) &- self)
    }
    
}

/**
 OTP Layer
 
 Implements the OTP Layer and handles creation and parsing.

*/

struct OTPLayer {
    
    /// The offset from which length counting begins.
    static let lengthCountOffset = Self.Offset.footerOptions.rawValue
    
    /// The packet identifier which begins every OTP message.
    static let packetIdentifier = Data([0x4f, 0x54, 0x50, 0x2d, 0x45, 0x31, 0x2e, 0x35, 0x39, 0x00, 0x00, 0x00])
    
    /// The size of the rolling window of transform folios from a particular `OTPProducer`.
    static let transformFolioWindow = 5

    /**
     OTP Layer Vectors
     
     Enumerates the supported Vectors for this layer.
     
    */
    enum Vector: PDUVector {
        
        /// Contains a  `TransformLayer`.
        case transformMessage = 0xFF01
        
        /// Contains a  `AdvertisementLayer`.
        case advertisementMessage = 0xFF02
        
    }
    
    /**
     OTP Layer Data Offsets

     Enumerates the data offset for each field in this layer.
     
    */
    enum Offset: Int {
        case packetIdentifier = 0
        case vector = 12
        case length = 14
        case footerOptions = 16
        case footerLength = 17
        case cid = 18
        case folio = 34
        case page = 38
        case lastPage = 40
        case options = 42
        case reserved = 43
        case componentName = 47
        case data = 79
    }
    
    /// The vector describing the data in the layer.
    var vector: Vector
    
    /// A globally unique identifier (UUID) representing the `Component`, compliant with RFC 4122.
    var cid: CID
    
    /// The folio number for this message.
    var folio: FolioNumber
    
    /// The page number for this message within this this folio number.
    var page: Page
    
    /// The final page number for messages with this folio number.
    var lastPage: Page
    
    /// A name for this `Component`, such as a user specified human-readable string, or serial number for the device.
    var componentName: ComponentName
    
    /// The data contained in the layer.
    var data: Data
    
    /**
     Creates an OTP Layer as Data.
     
     - Parameters:
        - vector: The Vector of this layer.
        - cid: The CID of this Component.
        - nameData: The name of this Component as Data.
        - folio: Optional: Folio Number for this layer.
        - page: Optional: Page Number for this layer.
        - lastPage: Optional: Last Page Number for this layer.

     - Returns: An `OTPLayer` as a `Data` object.

    */
    static func createAsData(with vector: Vector, cid: CID, nameData: Data, folio: FolioNumber = FolioNumber.min, page: Page = Page.min, lastPage: Page = Page.min) -> Data {

        var data = Data()
        
        // the packet identifier
        data.append(contentsOf: OTPLayer.packetIdentifier)
        
        // this vector for this message
        data.append(vector.rawValue.data)
        
        // length of pdu [placeholder]
        data.append(contentsOf: [0x00, 0x00])
        
        // footer options
        data.append(0x00)
        
        // footer length
        data.append(0x00)

        // the cid of the component
        data.append(cid.data)

        // the folio number
        data.append(folio.data)
        
        // page number
        data.append(contentsOf: page.data)
        
        // the number of the final page
        data.append(contentsOf: lastPage.data)
        
        // options
        data.append(0x00)

        // reserved
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        // the name of this component
        data.append(nameData)

        return data
        
    }
    
    /**
     Attempts to create an OTP Layer from the data.
     
     - Parameters:
        - data: The data to be parsed.
     
     - Throws: An error of type `OTPLayerValidationError`
     
     - Returns: A valid `OTPLayer`.
          
    */
    static func parse(fromData data: Data) throws -> Self {

        // there must be a complete OTP layer, which is no greater than the required max length
        guard (Offset.data.rawValue...UDP.maxMessageLength).contains(data.count) else { throw OTPLayerValidationError.lengthOutOfRange }

        // the packet identifier
        guard data[...(Offset.vector.rawValue-1)] == Self.packetIdentifier else { throw OTPLayerValidationError.invalidPacketIdentifier }

        // the vector for this message
        guard let vector: PDUVector = data.toUInt16(atOffset: Offset.vector.rawValue) else { throw OTPLayerValidationError.unableToParse(field: "Vector") }
        
        // Checkpoint: the vector must be supported
        guard let validVector = Vector.init(rawValue: vector) else { throw OTPLayerValidationError.invalidVector(vector) }

        // length of pdu
        guard let length: OTPPDULength = data.toUInt16(atOffset: Offset.length.rawValue) else { throw OTPLayerValidationError.unableToParse(field: "Length") }

        // footer options
        // ignore
        
        // footer length
        guard let footerLength: FooterLength = data.toUInt8(atOffset: Offset.footerLength.rawValue) else { throw OTPLayerValidationError.unableToParse(field: "Footer Length") }
        
        // Checkpoint: the length of the message must greater than the data and equal that in the pdu length field + footer length field
        guard Int(length) + Self.lengthCountOffset >= Offset.data.rawValue && data.count - Self.lengthCountOffset == length + OTPPDULength(footerLength) else { throw OTPLayerValidationError.invalidLength(length, footerLength) }
        
        // the cid of the component
        guard let cid: CID = data.toUUID(atOffset: Offset.cid.rawValue) else { throw OTPLayerValidationError.unableToParse(field: "CID") }

        // the folio number
        guard let folioNumber: FolioNumber = data.toUInt32(atOffset: Offset.folio.rawValue) else { throw OTPLayerValidationError.unableToParse(field: "Folio Number") }

        // page number
        guard let page: Page = data.toUInt16(atOffset: Offset.page.rawValue) else { throw OTPLayerValidationError.unableToParse(field: "Page") }

        // the number of the final page
        guard let lastPage: Page = data.toUInt16(atOffset: Offset.lastPage.rawValue) else { throw OTPLayerValidationError.unableToParse(field: "Last Page") }

        // options
        // ignore

        // reserved
        // ignore
        
        // the name of this component
        guard let componentName: ComponentName = data.toString(ofLength: ComponentName.maxComponentNameBytes, atOffset: OTPLayer.Offset.componentName.rawValue) else { throw OTPLayerValidationError.unableToParse(field: "Component Name") }

        // layer data
        let data = data.subdata(in: Offset.data.rawValue..<Int(length) + Self.lengthCountOffset)
        
        return Self(vector: validVector, cid: cid, folio: folioNumber, page: page, lastPage: lastPage, componentName: componentName, data: data)
        
    }
    
    /**
     Calculates whether this layer contain a folio number which is considered 'part of the current communication'.
     
     - Parameters:
        - previousFolio: The previously received folio number.
        - previousPage: The previously received page (not providing this assumes a message type that only ever has a single page e.g. system advertisement).

     - Returns: Whether this is considered 'part of the current communication' (in sequence).
          
    */
    func isPartOfCurrentCommunication(previousFolio: FolioNumber, previousPage: Page = 0) -> Bool {
        
        // if the folio is the same allow different pages, but not duplicates
        if self.folio == previousFolio {
            return self.page != page
        }
        
        // determine if this folio number is considered part of the current communication.
        switch self.vector {
        case .advertisementMessage:
            return self.folio.isPartOfCurrentCommunication(previous: previousFolio)
        case .transformMessage:
            return self.folio.isPartOfCurrentCommunication(previous: previousFolio, window: FolioNumber(Self.transformFolioWindow))
        }
  
    }
    
}

/**
 OTP Layer Data Extension
 
 Extensions for modifying fields within an existing `OTPLayer` stored as `Data`.
 
*/

internal extension Data {
    
    /**
    Replaces the `OTPLayer` page field.
     
     - Parameters:
        - page: The page number to be replaced in the layer.

    */
    mutating func replacingOTPLayerPage(with page: Page) {
        self.replaceSubrange(OTPLayer.Offset.page.rawValue...OTPLayer.Offset.page.rawValue+1, with: page.data)
    }
    
    /**
    Replaces the `OTPLayer` last page field.
     
     - Parameters:
        - page: The page number to be replaced in the layer.

    */
    mutating func replacingOTPLayerLastPage(with page: Page) {
        self.replaceSubrange(OTPLayer.Offset.lastPage.rawValue...OTPLayer.Offset.lastPage.rawValue+1, with: page.data)
    }
    
    /**
    Replaces the `OTPLayer` folio field.
     
     - Parameters:
        - folio: The folio number to be replaced in the layer.

    */
    mutating func replacingOTPLayerFolio(with folio: FolioNumber) {
        self.replaceSubrange(OTPLayer.Offset.folio.rawValue...OTPLayer.Offset.folio.rawValue+3, with: folio.data)
    }
    
}

/**
 OTP Layer Validation Error
 
 Enumerates all possible `OTPLayer` parsing errors.
 
*/

enum OTPLayerValidationError: LocalizedError {
    
    /// The data is either of insufficient length, or larger than permitted.
    case lengthOutOfRange
    
    /// The packet identifier does not match that specified for OTP.
    case invalidPacketIdentifier
    
    /// The length or footer length fields do not match the actual data length.
    case invalidLength(_ length: OTPPDULength, _ footerLength: FooterLength)
    
    /// The `Vector` is not recognized.
    case invalidVector(_ vector: PDUVector)
    
    /// The `FolioNumber` is not considered 'part of the current communication'.
    case folioOutOfRange(_ cid: CID)
    
    /// A field could not be parsed from the data.
    case unableToParse(field: String)

    /**
     A human-readable description of the error useful for logging purposes.
    */
    var logDescription: String {
        switch self {
        case .lengthOutOfRange:
            return "Length out of range for OTP Layer."
        case .invalidPacketIdentifier:
            return "Invalid Packet Identifier in OTP Layer."
        case let .invalidLength(length, footerLength):
            return "Invalid Length \(length) or Footer Length \(footerLength) in OTP Layer."
        case let .invalidVector(vector):
            return "Invalid Vector \(vector) in OTP Layer."
        case let .folioOutOfRange(cid):
            return "Folio Number not 'part of current communication' for \(cid)"
        case let .unableToParse(field):
            return "Unable to parse \(field) in OTP Layer."
        }
    }
        
}
