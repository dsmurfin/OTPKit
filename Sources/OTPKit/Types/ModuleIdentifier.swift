//
//  ModuleIdentifier.swift
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
 OTP Module Identifier
 
 The combination of `OTPManufacturerID`, `OTPModuleNumber`, which uniquely identifies an `OTPModule`.
 
*/

public struct OTPModuleIdentifier: Comparable, Hashable {
    
    /**
     Identifies the manufacturer, using an ESTA assigned Manufacturer ID.
     
     [ESTA TSP Manufacturer IDs]:
     https://tsp.esta.org/tsp/working_groups/CP/mfctrIDs.php
     
     For more information, see [ESTA TSP Manufacturer IDs].
     
    */
    var manufacturerID: OTPManufacturerID
    
    /// Identifies the module, unique to a specific `OTPManufacturerID`.
    var moduleNumber: OTPModuleNumber
    
    /// A human-readable log description of this module identifier
    public var logDescription: String {
        "\(manufacturerID):\(moduleNumber)"
    }

    /**
     OTP Module Identifier `Comparable`
     
     - Parameters:
        - lhs: The first instance to be compared.
        - rhs: The second instance to be compared.
     
     - Returns: Whether the first instance is considered smaller than the second.
     
    */
    public static func < (lhs: Self, rhs: Self) -> Bool {

        // first compare by manufacturerID
        if lhs.manufacturerID != rhs.manufacturerID {
            return lhs.manufacturerID < rhs.manufacturerID
        } else {
            return lhs.moduleNumber < rhs.moduleNumber
        }
        
    }
    
}

/**
 Module Identifier Notification
 
 Links an `OTPModuleIdentifier` with a `Date`. Used by `OTPProducer`s to store the last time they are notified by an `OTPConsumer` that it wishes to receive `OTPModule`s with this identifier.
 
*/

struct ModuleIdentifierNotification: Comparable, Hashable {
    
    /// Identifies the module.
    var moduleIdentifier: OTPModuleIdentifier
    
    /// The date/time this `OTPModuleIdentifier` was received in a module advertisement message.
    var notified: Date
    
    /**
     Module Identifier Notification `Equatable`
     
     - Parameters:
        - lhs: The first instance to be compared.
        - rhs: The second instance to be compared.
     
     - Returns: Whether the instances are considered equal.
     
    */
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.moduleIdentifier == rhs.moduleIdentifier
    }
    
    /**
     Module Identifier Notification `Comparable`
     
     - Parameters:
        - lhs: The first instance to be compared.
        - rhs: The second instance to be compared.
     
     - Returns: Whether the first instance is considered smaller than the second.
     
    */
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.moduleIdentifier < rhs.moduleIdentifier
    }
    
    /**
     Module Identifier Notification `Hashable`
     
     - Parameters:
        - hashable: The hasher to use when combining the components of this instance.
     
    */
    func hash(into hasher: inout Hasher) {
        hasher.combine(moduleIdentifier)
    }
    
}
