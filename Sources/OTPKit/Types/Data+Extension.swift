//
//  Data+Extension.swift
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
 Data Extension
 
 Extensions to `Data`.

*/

extension Data {
    
    /**
     Attempts to create a UInt8 from this data at a specified offset.

     - Parameters:
        - offset: The offset at which to access the value.
     
     - Returns: An optional UInt8 value.

    */
    internal func toUInt8(atOffset offset: Int) -> UInt8? {
        self.withUnsafeBytes { $0.baseAddress?.loadUnaligned(atOffset: offset, as: UInt8.self) }
    }

    /**
     Attempts to create a UInt16 from this data at a specified offset.

     - Parameters:
        - offset: The offset at which to access the value.
     
     - Returns: An optional UInt16 value.
     
    */
    internal func toUInt16(atOffset offset: Int) -> UInt16? {
        self.withUnsafeBytes { $0.baseAddress?.loadUnaligned(atOffset: offset, as: UInt16.self).bigEndian }
    }

    /**
     Attempts to create a UInt32 from this data at a specified offset.

     - Parameters:
        - offset: The offset at which to access the value.
     
     - Returns: An optional UInt32 value.
     
    */
    internal func toUInt32(atOffset offset: Int) -> UInt32? {
        self.withUnsafeBytes { $0.baseAddress?.loadUnaligned(atOffset: offset, as: UInt32.self).bigEndian }
    }
    
    /**
     Attempts to create an Int32 from this data at a specified offset.

     - Parameters:
        - offset: The offset at which to access the value.
     
     - Returns: An optional Int32 value.
     
    */
    internal func toInt32(atOffset offset: Int) -> Int32? {
        self.withUnsafeBytes { $0.baseAddress?.loadUnaligned(atOffset: offset, as: Int32.self).bigEndian }
    }
    
    /**
     Attempts to create a UInt64 from this data at a specified offset.

     - Parameters:
        - offset: The offset at which to access the value.
     
     - Returns: An optional UInt64 value.

     
    */
    internal func toUInt64(atOffset offset: Int) -> UInt64? {
        self.withUnsafeBytes { $0.baseAddress?.loadUnaligned(atOffset: offset, as: UInt64.self).bigEndian }
    }
    
    /**
     Attempts to create a UUID from this data at a specified offset.

     - Parameters:
        - offset: The offset at which to access the value.
     
     - Returns: An optional UUID value.
     
    */
    internal func toUUID(atOffset offset: Int) -> UUID? {

        var bytes = [UInt8]()
        for index in offset..<offset+16 {
            guard let byte = self.toUInt8(atOffset: index) else { return nil }
            bytes.append(byte)
        }
        return NSUUID(uuidBytes: bytes) as UUID

    }
    
    /**
     Attempts to create a String of a certain length from this data at a specified offset.

     - Parameters:
        - length: The length of string in bytes.
        - offset: The offset at which to access the value.
     
     - Returns: An optional String value.

    */
    internal func toString(ofLength length: Int, atOffset offset: Int) -> String? {
        guard offset+length <= self.count else { return nil }
        let data = self.subdata(in: offset..<offset+length)
        return String.init(data: data, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
    }
    
    /**
     Attempts to create a Module Identifier from this data at a specified offset.

     - Parameters:
        - offset: The offset at which to access the value.
     
     - Returns: An optional `OTPModuleIdentifier`.
     
    */
    internal func toModuleIdentifier(atOffset offset: Int) -> OTPModuleIdentifier? {
        guard let manufacturerID = self.toUInt16(atOffset: offset), let moduleNumber = self.toUInt16(atOffset: offset+2) else { return nil }
        return OTPModuleIdentifier(manufacturerID: manufacturerID, moduleNumber: moduleNumber)
    }
    
    /**
     Attempts to create an Address Point Description from this data at a specified offset.

     - Parameters:
        - offset: The offset at which to access the value.
     
     - Returns: An optional `AddressPointDescription`.
     
    */
    internal func toAddressPointDescription(atOffset offset: Int) -> AddressPointDescription? {
        guard let systemNumber: SystemNumber = self.toUInt8(atOffset: offset), let groupNumber: GroupNumber = self.toUInt16(atOffset: offset+1), let pointNumber: PointNumber = self.toUInt32(atOffset: offset+3), let pointName = self.toString(ofLength: PointName.maxPointNameBytes, atOffset: offset+7) else { return nil }
        let address = OTPAddress(system: systemNumber, group: groupNumber, point: pointNumber)
        return AddressPointDescription(address: address, pointName: pointName)
    }
    
    /**
     Replaces the PDU length field with the computed length.
     
     - Parameters:
        - length: The calculated length of this layer.
        - offset: The offset at which to replace with the length data.

    */
    internal mutating func replacingPDULength(_ length: OTPPDULength, at offset: Int) {
        self.replaceSubrange(offset...offset+1, with: length.data)
    }

    /**
     Creates a hex encoded string from this data object.
     
     - Returns: A hex encoded String representing this data.

    */
    internal func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
}

/**
 UInt8 Extension
 
 Data Extensions to `UInt8`.

*/

internal extension UInt8 {

    /**
     Creates a data object with this value.
    */
    var data: Data {
        var value = self
        return withUnsafePointer(to: &value) {
            Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
        }
    }
    
    /**
     Creates an array of 8 boolean values from the bits of this UInt8.
    */
    var optionsFlags: [Bool] {
        
        var byte = self
        var bits = [Bool](repeating: false, count: 8)
        
        for i in 0..<8 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[i] = true
            }
            byte >>= 1
        }

        return bits
        
    }
    
}

/**
 UInt16 Extension
 
 Data Extensions to `UInt16`.

*/

internal extension UInt16 {
    
    /**
     Creates a data object with this value.
    */
    var data: Data {
        var value = self.bigEndian
        return withUnsafePointer(to: &value) {
            Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
        }
    }
    
}

/**
 UInt32 Extension
 
 Data Extensions to `UInt32`.

*/

internal extension UInt32 {
    
    /**
     Creates a data object with this value.
    */
    var data: Data {
        var value = self.bigEndian
        return withUnsafePointer(to: &value) {
            Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
        }
    }
    
}

/**
 Int32 Extension
 
 Data Extensions to `Int32`.

*/

internal extension Int32 {
    
    /**
     Creates a data object with this value.
    */
    var data: Data {
        var value = self.bigEndian
        return withUnsafePointer(to: &value) {
            Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
        }
    }
    
}

/**
 UInt64 Extension
 
 Data Extensions to `UInt64`.

*/

internal extension UInt64 {
    
    /**
     Creates a data object with this value.
    */
    var data: Data {
        var value = self.bigEndian
        return withUnsafePointer(to: &value) {
            Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
        }
    }
    
}

/**
 UUID Extension
 
 Data Extensions to `UUID`.

*/

internal extension UUID {
    
    /**
     Creates a data object with this value.
    */
    var data: Data {
        withUnsafeBytes(of: self.uuid, { Data($0) })
    }
    
}

/**
 String Extension
 
 Data Extensions to `String`.

*/

internal extension String {
    
    /**
     Creates a data object with this value but with a fixed length.

     - Parameters:
        - length: The total resulting length in bytes for this Data object.
     
     - Returns: A Data object from the Unicode String truncated to a maximum number of bytes and padded with 0s

    */
    func data(paddedTo length: Int) -> Data {

        // get the first maxLength valid unicode bytes
        var truncatedString = self.truncated(toMaxBytes: length)
        
        // pad if neccessary
        for _ in truncatedString.utf8.count..<length {
            truncatedString.append("\0")
        }
        
        if let data = truncatedString.data(using: .utf8) {
            return data
        } else {
            return Data((0..<length).map { _ in UInt8(0) })
        }
        
    }
    
    /**
     Creates a string truncated to a safe Unicode boundary to a maximum number of bytes.

     - Parameters:
        - maxBytes: The maximum number of bytes for this string.
     
     - Returns: A valid Unicode String truncated to a maximum number of bytes.

    */
    func truncated(toMaxBytes maxBytes: Int) -> String {

        guard let data = self.data(using: .utf8) else { return "" }
        
        // if the string bytes aren't greater just return it
        guard data.count > maxBytes else { return self }

        var bytesCount = 0
        for (index, character) in self.enumerated() {

            // get the character as data
            guard let data = String(character).data(using: .utf8) else { continue }

            // ensure the data would not be longer than max bytes
            guard bytesCount + data.count <= maxBytes else {

                let previousIndex = self.index(self.startIndex, offsetBy: index-1)

                return String(self[...previousIndex])
           
            }

            bytesCount += data.count

        }
       
       return ""
        
    }
    
}

/**
 OTP Module Identifier Extension
 
 Data Extensions to `OTPModuleIdentifier`.

*/

internal extension OTPModuleIdentifier {
    
    /**
     Creates a data object with this value.
    */
    var data: Data {
        self.manufacturerID.data + self.moduleNumber.data
    }
    
}

/**
 Address Point Description Extension
 
 Data Extensions to `AddressPointDescription`.

*/

internal extension AddressPointDescription {
    
    /**
     Creates a data object with this value.
    */
    var data: Data {
        self.systemNumber.data + self.groupNumber.data + self.pointNumber.data + self.pointName.data(paddedTo: PointName.maxPointNameBytes)
    }
    
}

/**
 Unsafe Raw Pointer
 
 Data Extensions to `UnsafeRawPointer`.

*/

internal extension UnsafeRawPointer {
  
    /**
     Loads a value from memory, even it is is unaligned.
     
     - Parameters:
        - offset: The offset at which to load the value.
        - type: The type to be loaded.

    */
    func loadUnaligned<T>(atOffset offset: Int, as: T.Type) -> T {
        assert(_isPOD(T.self)) // relies on the type being POD (no refcounting or other management)
        let buffer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { buffer.deallocate() }
        memcpy(buffer, self+offset, MemoryLayout<T>.size)
        return buffer.pointee
    }
    
}
