//
//  AddressPointDescription.swift
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
 Address Point Description
 
 The combination of `SystemNumber`, `GroupNumber`, `PointNumber` and `PointName` make up the `AddressPointDescription` which describes an `OTPPoint`.
 
*/

struct AddressPointDescription: Comparable, Hashable {

    /// The system number component identifying the `OTPPoint`.
    var systemNumber: SystemNumber
    
    /// The group number component identifying the `OTPPoint`.
    var groupNumber: GroupNumber
    
    /// The point number component identifying the `OTPPoint`.
    var pointNumber: PointNumber
    
    /// The human-readable name for the `OTPPoint` identified.
    var pointName: PointName
    
    /// The `OTPAddress` identifying the `OTPPoint`
    var address: OTPAddress {
        return OTPAddress(system: systemNumber, group: groupNumber, point: pointNumber)
    }

    /**
     Initializes a new Address Point Description.

     - Parameters:
        - address: The Address of the Point.
        - pointName: The name of the Point with this Address.

    */
    init(address: OTPAddress, pointName: PointName) {
        self.systemNumber = address.systemNumber
        self.groupNumber = address.groupNumber
        self.pointNumber = address.pointNumber
        self.pointName = pointName
    }
    
    /**
     Address Point Description `Equatable`
     
     - Parameters:
        - lhs: The first instance to be compared.
        - rhs: The second instance to be compared.
     
     - Returns: Whether the instances are considered equal.
     
    */
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.address == rhs.address
    }
    
    /**
     Address Point Description `Comparable`
     
     - Parameters:
        - lhs: The first instance to be compared.
        - rhs: The second instance to be compared.
     
     - Returns: Whether the first instance is considered smaller than the second.
     
    */
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.address < rhs.address
    }
    
    /**
     Address Point Description `Hashable`
     
     - Parameters:
        - hashable: The hasher to use when combining the components of this instance.
     
    */
    func hash(into hasher: inout Hasher) {
        hasher.combine(systemNumber)
        hasher.combine(groupNumber)
        hasher.combine(pointNumber)
    }

}
