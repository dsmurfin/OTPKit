//
//  Point.swift
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
 A type used for the priority component of an`OTPPoint` or `Point`.
 
 Valid numbers are in the range 1 (low) - 200 (high).

*/
typealias Priority = UInt8

/**
 Priority Extension
 
 Extensions to `Priority`.

*/

extension Priority {
    
    /// The minimum permitted value for `Priority`.
    static let minPriority: Priority = 0
    
    /// The maximum permitted value for `Priority`.
    static let maxPriority: Priority = 200
    
    /// The default value for `Priority` used where not specified.
    static let defaultPriority: Priority = 100
    
    /**
     Determines whether this Priority is valid.

     - Throws: `PointValidationError.invalidPriority` if less than 1 or greater than 200.
     
    */
    func validPriority() throws {
        guard Priority.minPriority...Priority.maxPriority ~= self else { throw OTPPointValidationError.invalidPriority }
    }
    
    /**
     Calculates the nearest valid `Priority` to the one specified.

     - Returns: A valid priority nearest to the value specified.
     
    */
    func nearestValidPriority() -> Priority {
        self < Self.minPriority ? Self.minPriority : self > Self.maxPriority ? Self.maxPriority : self
    }
    
}

/// A type used for the human-readable name of a Point.

typealias PointName = String

/**
 Point Name Extension
 
 Extensions to `PointName`.

*/
extension PointName {
    
    /// The maximum size of a `PointName` in bytes.
    static let maxPointNameBytes: Int = 32
    
}

/**
 Point
 
 The smallest, indivisible component having properties of motion. This may be the center of a complex Object, or merely one of many Points on it.
 
 Points are identified using an `OTPAddress`, and contain `OTPModule`s containing transform information about the point.

*/

protocol Point {

    /// The `OTPAddress` identifying the point.
    var address: OTPAddress { get set }
    
    /// The `Priority` of the point, used when arbitrating between multiple points with the same `OTPAddress`.
    var priority: Priority { get set }
    
    /// A human-readable name for this point.
    var name: PointName { get set }
    
    /// The `name` of the point stored as `Data`.
    var nameData: Data { get set }
    
    /// An array of `OTPModule`s containing transform information describing the point.
    var modules: [OTPModule] { get set }
    
    /// Whether the point has changes which have not yet been communicated to an observer.
    var hasChanges: Bool { get set }
    
}

/**
 Point Extension
 
 Extensions to `Point` inherited by all implementors of the protocol.

*/

extension Point {
    
    /**
     Renames the Point

     - Parameters:
        - name: A human-readable name for this Point.

    */
    mutating func rename(name: PointName) {
        if name != self.name {
            self.name = name
            self.nameData = name.data(paddedTo: PointName.maxPointNameBytes)
        }
    }
    
}

/**
 OTP Point
 
 The smallest, indivisible component having properties of motion. This may be the center of a complex Object, or merely one of many Points on it.
  
 OTP Points are identified using an `OTPAddress`, and contain `OTPModule`s containing transform information about the point. They may optionally have a CID identifier and sampled timestamp for a winning `OTPProducer`.

*/

public struct OTPPoint: Comparable, Hashable {

    /// The `OTPAddress` identifying the point.
    public var address: OTPAddress
    
    /// The priority of the point, used when arbitrating between multiple points with the same `OTPAddress`.
    public var priority: UInt8
    
    /// A human-readable name for this point.
    public var name: String
    
    /// The modules for this point.
    public var modules: [OTPModule]
    
    /// An optional winning CID for this point (when from a producer).
    public var cid: UUID?
    
    /// An optional sampled time for this point (when from a producer).
    public var sampled: UInt64?
    
    /**
     Initializes a new OTP Point.

     - Parameters:
        - address: The Address of the Point.
        - priority: The Priority for this Point.
        - name: Optional: A human-readable name for this Point.

    */
    public init(address: OTPAddress, priority: UInt8, name: String = "") {
        self.address = address
        self.priority = priority
        self.name = name
        self.modules = []
    }
    
    /**
     Initializes a new OTP Point received from a Producer.

     - Parameters:
        - address: The Address of the Point.
        - priority: The Priority for this Point.
        - name: A human-readable name for this Point.
        - cid: An optional CID of the highest priority Producer for this Point.
        - sampled: An optional sample time for this Point.
        - module: The modules containing the data for this Point.

    */
    init(address: OTPAddress, priority: UInt8, name: String, cid: UUID?, sampled: UInt64?, modules: [OTPModule]) {
        self.address = address
        self.priority = priority
        self.name = name
        self.cid = cid
        self.sampled = sampled
        self.modules = modules
    }

    /**
     OTP Point `Equatable`
     
     - Parameters:
        - lhs: The first instance to be compared.
        - rhs: The second instance to be compared.
     
     - Returns: Whether the instances are considered equal.
     
    */
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.address == rhs.address
    }
    
    /**
     OTP Point `Comparable`
     
     - Parameters:
        - lhs: The first instance to be compared.
        - rhs: The second instance to be compared.
     
     - Returns: Whether the first instance is considered smaller than the second.
     
    */
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.address < rhs.address
    }
    
    /**
     OTP Point `Hashable`
     
     - Parameters:
        - hashable: The hasher to use when combining the components of this instance.
     
    */
    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
    
}

/**
 Producer Point
 
 Used by `OTPProducer`s to store points for transmission.

*/

struct ProducerPoint: Point {
    
    /// The number of messages a changed point should be transmitted in before ceasing transmission.
    private static let ceaseTransmissionCount = 4
    
    /// The `OTPAddress` identifying the point.
    var address: OTPAddress
    
    /// The `Priority` of the point, used when arbitrating between multiple points with the same `OTPAddress`.
    var priority: Priority
    
    /// A human-readable name for this point.
    var name: PointName
    
    /// The `name` of the point stored as `Data`.
    var nameData: Data
    
    /// An array of `OTPModule`s containing transform information describing the point.
    var modules: [OTPModule]
    
    /// Whether this point has changes which have not yet been transmitted.
    var hasChanges: Bool {
        didSet {
            changeTransmitsRemaining = hasChanges ? Self.ceaseTransmissionCount : max(changeTransmitsRemaining-1, 0)
        }
    }
    
    /// Whether this point contains `OTPModule`s which have been requested by an `OTPConsumer`.
    var hasRequestedModules: Bool

    /// The number of milliseconds since the 'Time Origin' of the `OTPProducer` that this Point was sampled.
    var sampled: Timestamp?

    /// The count of remaining messages the point should be transmitted in.
    private var changeTransmitsRemaining: Int
    
    /**
     Initializes a new Producer Point

     - Parameters:
        - address: The Address of the Point.
        - priority: The Priority for this Point.
        - name: A human-readable name for this Point.

    */
    init(address: OTPAddress, priority: Priority, name: PointName) {
        self.address = address
        self.priority = priority
        self.name = name
        self.nameData = name.data(paddedTo: PointName.maxPointNameBytes)
        self.modules = []
        self.hasChanges = true
        self.hasRequestedModules = false
        self.changeTransmitsRemaining = Self.ceaseTransmissionCount
    }
    
    /**
     Adds a new Module to the Producer Point

     - Parameters:
        - module: The Module to add.
     
     - Throws: An error of type `PointValidationError`

    */
    mutating func addModule(_ module: OTPModule, timeOrigin: Date) throws {
        
        guard !self.modules.contains(where: { $0.moduleIdentifier == module.moduleIdentifier }) else {
            throw OTPPointValidationError.moduleExists
        }
        
        // are there any associated modules?
        if let associatedModules = ModuleAssociations.associations.first(where: { $0.source.identifier == module.moduleIdentifier })?.associated {

            for associatedModule in associatedModules {
                
                // the associated module must not already exist
                guard !self.modules.contains(where: { $0.moduleIdentifier == associatedModule.identifier }) else { continue }
                
                // create the associated module with default values
                let module = associatedModule.init()
                
                self.modules.append(module)
                
            }
            
        }

        self.modules.append(module)
        
        // this point has a new module, therefore has changes
        self.hasChanges = true
        
        // this point has newly sampled data
        self.sampled = Timestamp(Date().timeIntervalSince(timeOrigin) * 1000000)
        
    }
    
    /**
     Removes a Module from the Producer Point.

     - Parameters:
        - identifier: The Module Identifier of the Module to remove.
     
     - Throws: An error of type `PointValidationError`

    */
    mutating func removeModule(with identifier: OTPModuleIdentifier) throws {
        
        guard self.modules.contains(where: { $0.moduleIdentifier == identifier }) else {
            throw OTPPointValidationError.moduleNotExists
        }
        
        // are there any associated modules?
        let associatedModuleIdentifiers = ModuleAssociations.associations.filter { $0.associated.contains(where: { $0.identifier == identifier }) }.map { $0.source.identifier }

        for associatedModuleIdentifier in associatedModuleIdentifiers {
            
            // associated modules must be removed first
            if self.modules.contains(where: { $0.moduleIdentifier == associatedModuleIdentifier }) {
                throw OTPPointValidationError.moduleAssociatedExists
            }

        }
        
        modules = modules.filter { $0.moduleIdentifier != identifier }
        
        // this point has different modules, therefore has changes
        self.hasChanges = true
        
        // if no modules remain this point is no longer sampled
        if modules.count == 0 {
            sampled = nil
        }
        
    }
    
    /**
     Updates an existing Module for the Producer Point

     - Parameters:
        - module: The Module to update.
        - timeOrigin: The time origin of the Producer.

     - Throws: An error of type `PointValidationError`

    */
    mutating func update(module: OTPModule, timeOrigin: Date) throws {
        
        guard let moduleIndex = self.modules.firstIndex(where: { $0.moduleIdentifier == module.moduleIdentifier }) else {
            throw OTPPointValidationError.moduleNotExists
        }
        
        self.modules[moduleIndex] = module
        
        // this point has new module data, therefore has changes
        self.hasChanges = true

        // this point has newly sampled data
        self.sampled = Timestamp(Date().timeIntervalSince(timeOrigin) * 1000000)

    }
    
    /**
     Determines if this Point should be included in messages.

     - Parameters:
        - fullPointSet: Whether these messages should include a full set of Points.
     
     - Returns: Whether this point should be included in messages.

    */
    func includeInMessages(fullPointSet: Bool) -> Bool {
        (fullPointSet || changeTransmitsRemaining > 0) && hasRequestedModules && sampled != nil
    }
    
}

/**
 Consumer Point
 
 Used by `OTPConsumer`s to store points received from `OTPProducer`s.

*/

struct ConsumerPoint: Point, Comparable, Hashable {
    
    /// The `OTPAddress` identifying the point.
    var address: OTPAddress
    
    /// The `Priority` of the point, used when arbitrating between multiple points with the same `OTPAddress`.
    var priority: Priority
    
    /// A human-readable name for this point.
    var name: PointName
    
    /// The `name` of the point stored as `Data`.
    var nameData: Data
    
    /// An array of `OTPModule`s containing transform information describing the point.
    var modules: [OTPModule]
    
    /// Whether the point has changes which have not yet been communicated to an observer.
    var hasChanges: Bool
    
    /// The number of milliseconds since the 'Time Origin' of the `OTPProducer` that this Point was sampled.
    var sampled: Timestamp?
    
    /// An optional `CID` identifying the `OTPProducer` which provided this point. Will be nil if a merged point has multiple `OTPProducer` sources.
    var cid: CID?
    
    /**
     Initializes a new Consumer Point

     - Parameters:
        - address: The Address of the Point.
        - priority: The Priority for this Point.
        - name: Optional: A human-readable name for this Point.
        - cid: Optional: An optional CID for this Producer transmitting this Point.
        - sampled: Optional: An optional sampled timestamp for this Point.
        - modules: The Modules contained in this Point.

    */
    init(address: OTPAddress, priority: Priority, name: PointName = "", cid: CID? = nil, sampled: Timestamp? = nil, modules: [OTPModule]) {
        self.address = address
        self.priority = priority
        self.name = name
        self.nameData = Data()
        self.cid = cid
        self.sampled = sampled
        self.modules = modules
        self.hasChanges = false
    }
    
    /**
     Updates the name of this Consumer Point if it can be found in an array of Address Point Descriptions.

     - Parameters:
        - addressPointDescriptions: The Address Point Descriptions which contain names for Points.

    */
    mutating func updateName(fromAddressPointDescriptions addressPointDescriptions: [AddressPointDescription]) {
        self.name = addressPointDescriptions.first(where: { $0.address == address })?.pointName ?? ""
    }
    
    /**
     Consumer Point `Equatable`
     
     - Parameters:
        - lhs: The first instance to be compared.
        - rhs: The second instance to be compared.
     
     - Returns: Whether the instances are considered equal.
     
    */
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.address == rhs.address && lhs.priority == rhs.priority
    }
    
    /**
     Consumer Point `Comparable`
     
     - Parameters:
        - lhs: The first instance to be compared.
        - rhs: The second instance to be compared.
     
     - Returns: Whether the first instance is considered smaller than the second.
     
    */
    public static func < (lhs: Self, rhs: Self) -> Bool {

        // compare by address, then priority
        if lhs.address != rhs.address {
            return lhs.address < rhs.address
        } else {
            return lhs.priority > rhs.priority
        }
        
    }
    
    /**
     Consumer Point `Hashable`
     
     - Parameters:
        - hashable: The hasher to use when combining the components of this instance.
     
    */
    func hash(into hasher: inout Hasher) {
        hasher.combine(address)
        hasher.combine(priority)
    }
    
}

/**
 Point Validation Error
 
 Enumerates all possible Point parsing errors.
 
*/

public enum OTPPointValidationError: LocalizedError {
    
    /// The point number is out-of-range.
    case invalidPointNumber
    
    /// The group number is out-of-range.
    case invalidGroupNumber
    
    /// The system number is out-of-range.
    case invalidSystemNumber
    
    /// The point number is out-of-range.
    case invalidPriority
    
    /// A point already exists with this `OTPAddress` and `Priority`.
    case exists
    
    /// There are no points with this `OTPAddress` and optionally `Priority`.
    case notExists(priority: Bool)
    
    /// This `OTPPoint` already contains an `OTPModule` with this `OTPModuleIdentifier`.
    case moduleExists
    
    /// Some `OTPPoint`s already contain an `OTPModule` with this `OTPModuleIdentifier`.
    case moduleSomeExist
    
    /// This `OTPPoint`does not contain an `OTPModule` with this `OTPModuleIdentifier`.
    case moduleNotExists
    
    /// Some `OTPPoints` with this `OTPAddress` do not contain an `OTPModule` with this `OTPModuleIdentifier`
    case moduleSomeNotExist
    
    /// It is not possible to remove this `OTPModule` until all associated modules have also been removed.
    case moduleAssociatedExists

    /**
     A human-readable description of the error.
    */
    public var logDescription: String {
        switch self {
        case .invalidPointNumber:
            return "Point Number must be between \(PointNumber.minPointNumber) and \(PointNumber.maxPointNumber)"
        case .invalidGroupNumber:
            return "Group Number must be between \(GroupNumber.minGroupNumber) and \(GroupNumber.maxGroupNumber)"
        case .invalidSystemNumber:
            return "System Number must be between \(SystemNumber.minSystemNumber) and \(SystemNumber.maxSystemNumber)"
        case .invalidPriority:
            return "Priority must be between \(Priority.minPriority) and \(Priority.maxPriority)"
        case .exists:
            return "A Point already exists with this Address and Priority"
        case let .notExists(priority):
            return priority ? "No Points exist with this Address and Priority" : "No Points exist with this Address"
        case .moduleExists:
            return "A Module already exists with this Module Identifier"
        case .moduleSomeExist:
            return "Some Points using this Address already contain this Module"
        case .moduleNotExists:
            return "No Module exists with this Module Identifier"
        case .moduleSomeNotExist:
            return "Some Points using this Address do not contain this Module"
        case .moduleAssociatedExists:
            return "All associated Modules must be removed before removing a Module of this type."
        }
    }
        
}
