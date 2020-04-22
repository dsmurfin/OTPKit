//
//  Module.swift
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

/// A type used for the manufacturer identifier, which uniquely identifies a module alongside the `OTPModuleNumber`.
public typealias OTPManufacturerID = UInt16

/// A type used for the module number, which uniquely identifies a module alongside the `OTPManufacturerID`.
public typealias OTPModuleNumber = UInt16

/**
 OTP Module
 
 An OTP Module contains specific transform information about an `OTPPoint` such as position, rotation and hierarchy.
 
 Implementors providing their own module types must implement all of these requirements for creating, sending and parsing received modules of that type.

*/

public protocol OTPModule {

    /// Uniquely identifies the module using an `OTPModuleIdentifier`.
    static var identifier: OTPModuleIdentifier { get }
    
    /// The size of the module's data in bytes.
    static var dataLength: OTPPDULength { get }
    
    /// The total size of the module in bytes, including identifiers and length.
    static var moduleLength: OTPPDULength { get }
    
    /// A human-readable log description of this module.
    var logDescription: String { get }
    
    /**
     Initializes this `OTPModule` with default values.

    */
    init()

    /**
     Creates a Module as Data.
     
     - Returns: The `OTPModule` as a `Data` object.

    */
    func createAsData() -> Data
    
    /**
     Attempts to create an `OTPModule` from the data.
     
     - Parameters:
        - data: The data to be parsed.
     
     - Throws: An error of type `ModuleLayerValidationError`.
     
     - Returns: A valid `OTPModule` and the length of the PDU.
          
    */
    static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength)
    
    /**
     Merges an arrray of modules.
     
     - Parameters:
        - modules: The `OTPModule`s to be merged.
     
     - Precondition: All modules must be of the same type.

     - Returns: An optional `OTPModule` of this type, and whether to exclude the `OTPPoint` due to a mismatch.

    */
    static func merge(modules: [OTPModule]) -> (module: Self?, excludePoint: Bool)
    
    /**
     Calculates whether this module is considered equal to another one.
     
     - Parameters:
        - module: The `OTPModule` to be compared against.
     
     - Precondition: Both modules must be of the same type.

     - Returns: Whether these `OTPModule`s are considered equal.

    */
    func isEqualToModule(_ module: OTPModule) -> Bool
    
}

/**
 OTP Module Extension
 
 Extensions to `OTPModule` inherited by all implementors of the protocol.

*/

extension OTPModule {

    /// An instance accessor of the static module identifier.
    public var moduleIdentifier: OTPModuleIdentifier {
        get {
            return Self.identifier
        }
    }
    
    /// The total size of the module in bytes, including identifiers and length.
    var moduleLength: OTPPDULength {
        Self.dataLength + OTPPDULength(ModuleLayer.Offset.data.rawValue)
    }
    
}

/**
 Module Associations
 
 Enumerates all associations between `OTPModule`s.

*/

enum ModuleAssociations {
    
    /// Tuples of source `OTPModule` type and an array of associated `OTPModule` types for the source.
    static let associations: [(source: OTPModule.Type, associated: [OTPModule.Type])] = [(source: OTPModulePositionVelAccel.self, associated: [OTPModulePosition.self]),
                                                                                   (source: OTPModuleRotationVelAccel.self, associated: [OTPModuleRotation.self])]
    
}
