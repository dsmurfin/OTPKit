//
//  Address.swift
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

/**
 A type used for the system number component of an `OTPAddress` used to identify `OTPPoint`s.
 
 Valid numbers are in the range 1-200.

*/
public typealias OTPSystemNumber = UInt8

/// An internal type used for the system number component of an `OTPAddress` used to identify `OTPPoint`s.
typealias SystemNumber = OTPSystemNumber

/**
 System Number Extension
 
 Extensions to `SystemNumber`.

*/

extension SystemNumber {
    
    /// The size of a `SystemNumber` in bytes.
    static let sizeOfSystemNumber = MemoryLayout<Self>.size
    
    /// The minimum permitted value for `SystemNumber`.
    static let minSystemNumber: SystemNumber = 1
    
    /// The maximum permitted value for `SystemNumber`.
    static let maxSystemNumber: SystemNumber = 200
    
    /**
     Determines whether this System Number is valid.

     - Throws: `PointValidationError.invalidSystem` if less than 1 or greater than 200.

     */
    func validSystemNumber() throws {
        guard SystemNumber.minSystemNumber...SystemNumber.maxSystemNumber ~= self else { throw OTPPointValidationError.invalidSystemNumber }
    }
    
}

/**
 A type used for the group number component of an `OTPAddress` used to identify `OTPPoint`s.
 
 Valid numbers are in the range 1-60,000.

*/
public typealias OTPGroupNumber = UInt16

/// An internal type used for the group number component of an `OTPAddress` used to identify `OTPPoint`s.
typealias GroupNumber = OTPGroupNumber

/**
 Group Number Extension
 
 Extensions to `GroupNumber`.

*/

extension GroupNumber {
    
    /// The minimum permitted value for `GroupNumber`.
    static let minGroupNumber: GroupNumber = 1
    
    /// The maximum permitted value for `GroupNumber`.
    static let maxGroupNumber: GroupNumber = 60000
    
    /**
     Determines whether this Group Number is valid.

     - Throws: `PointValidationError.invalidGroup` if less than 1 or greater than 60,000.

    */
    func validGroupNumber() throws {
        guard GroupNumber.minGroupNumber...GroupNumber.maxGroupNumber ~= self else { throw OTPPointValidationError.invalidGroupNumber }
    }
    
}

/**
 A type used for the point number component of an `OTPAddress` used to identify `OTPPoint`s.
 
 Valid numbers are in the range 1-4,000,000,000.

*/
public typealias OTPPointNumber = UInt32

/// An internal type used for the point number component of an `OTPAddress` used to identify `OTPPoint`s.
typealias PointNumber = OTPPointNumber

/**
 Point Number Extension
 
 Extensions to `PointNumber`.

*/

extension PointNumber {
    
    /// The minimum permitted value for `PointNumber`.
    static let minPointNumber: PointNumber = 1
    
    /// The maximum permitted value for `PointNumber`.
    static let maxPointNumber: PointNumber = 4000000000
    
    /**
     Determines whether this Point Number is valid.

     - Throws: `PointValidationError.invalidPoint` if less than 1 or greater than 4,000,000,000.

    */
    func validPointNumber() throws {
        guard PointNumber.minPointNumber...PointNumber.maxPointNumber ~= self else { throw OTPPointValidationError.invalidPointNumber }
    }
    
}

/**
 OTP Address
 
 The combination of `OTPSystemNumber`, `OTPGroupNumber`, and `OTPPointNumber` make up the `OTPAddress` which identifies an `OTPPoint`.
 
 It is intended that addresses are unique within the network, but duplicate addresses are handled using either the `OTPPriority` or merging algorithms.

*/

public struct OTPAddress: Comparable, Hashable {

    /// The system number component.
    public var systemNumber: OTPSystemNumber
    
    /// The group number component.
    public var groupNumber: OTPGroupNumber
    
    /// The point number component.
    public var pointNumber: OTPPointNumber
    
    /// A human-readable description of the address in the approved format.
    public var description: String {
        "\(systemNumber)/\(groupNumber)/\(pointNumber)"
    }
    
    /**
     Initializes a new OTP Address.

     - Parameters:
        - systemNumber: The System Number.
        - groupNumber: The Group Number.
        - pointNumber: The Point Number.
     
     - Throws: An error of type `PointValidationError`

    */
    public init(systemNumber: OTPSystemNumber, groupNumber: OTPGroupNumber, pointNumber: OTPPointNumber) throws {

        try systemNumber.validSystemNumber()
        try groupNumber.validGroupNumber()
        try pointNumber.validPointNumber()

        self.systemNumber = systemNumber
        self.groupNumber = groupNumber
        self.pointNumber = pointNumber

    }
    
    /**
     Initializes a new OTP Address.

     - Parameters:
        - systemNumber: The System Number.
        - groupNumber: The Group Number.
        - pointNumber: The Point Number.
     
     - Throws: An error of type `PointValidationError`

    */
    public init(_ systemNumber: OTPSystemNumber,_ groupNumber: OTPGroupNumber,_ pointNumber: OTPPointNumber) throws {
        
        try systemNumber.validSystemNumber()
        try groupNumber.validGroupNumber()
        try pointNumber.validPointNumber()
        
        self.systemNumber = systemNumber
        self.groupNumber = groupNumber
        self.pointNumber = pointNumber
        
    }
    
    /**
     Initializes a new OTP Address.

     - Parameters:
        - system: The System Number.
        - group: The Group Number.
        - point: The Point Number.
     
      When using this internal initializer implementors must check the Address is valid prior to initialization using `isValid()`.

    */
    init(system: OTPSystemNumber, group: OTPGroupNumber, point: OTPPointNumber) {
        self.systemNumber = system
        self.groupNumber = group
        self.pointNumber = point
    }
    
    /**
     Determines whether this OTP Address is valid.

     - Throws: An error of type `PointValidationError`

    */
    func isValid() throws {
        try pointNumber.validPointNumber()
        try groupNumber.validGroupNumber()
        try systemNumber.validSystemNumber()
    }
    
    /**
     OTP Address `Equatable`
     
     - Parameters:
        - lhs: The first instance to be compared.
        - rhs: The second instance to be compared.
     
     - Returns: Whether the instances are considered equal.
     
    */
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.systemNumber == rhs.systemNumber && lhs.groupNumber == rhs.groupNumber && lhs.pointNumber == rhs.pointNumber
    }
    
    /**
     OTP Address `Comparable`
     
     - Parameters:
        - lhs: The first instance to be compared.
        - rhs: The second instance to be compared.
     
     - Returns: Whether the first instance is considered smaller than the second.
     
    */
    public static func < (lhs: Self, rhs: Self) -> Bool {

        // first compare by system number, then group number, then point number
        if lhs.systemNumber != rhs.systemNumber {
            return lhs.systemNumber < rhs.systemNumber
        } else if lhs.groupNumber != rhs.groupNumber {
            return lhs.groupNumber < rhs.groupNumber
        } else {
            return lhs.pointNumber < rhs.pointNumber
        }
        
    }
    
    /**
     OTP Address `Hashable`
     
     - Parameters:
        - hashable: The hasher to use when combining the components of this instance.
     
    */
    public func hash(into hasher: inout Hasher) {
        hasher.combine(systemNumber)
        hasher.combine(groupNumber)
        hasher.combine(pointNumber)
    }
    
}
