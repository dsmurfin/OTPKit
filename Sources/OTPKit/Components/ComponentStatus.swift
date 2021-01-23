//
//  ComponentStatus.swift
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
 OTP Component State
 
 The transmit state of a component (offline, advertising, online).
 
 Enumerates the possible states of an `OTPComponent`.
 
*/
public enum OTPComponentState: String {
    
    /// This component is offline.
    case offline = "offline"
    
    /// This component is only responding to advertisement messages.
    case advertising = "advertising"
    
    /// This component is transmitting transform messages.
    case online = "online"
    
}

/**
 OTP Component Status
 
 All `OTPConsumerStatus`s and `OTPProducerStatus`s are OTP Components.
 
 The core requirements of an OTP Component Status.
 
*/

public protocol OTPComponentStatus {
    
    /// A globally unique identifier (UUID) representing the component, compliant with RFC 4122.
    var cid: UUID { get }
    
    /// A human-readable name for the component.
    var name: String { get set }
    
    /// The IP mode of the component.
    var ipMode: OTPIPMode { get set }
    
    /// The IP addresses of the component.
    var ipAddresses: [String] { get set }
    
    /// The number of sequence errors in advertisement messages from the component.
    var sequenceErrors: Int { get set }
    
    /// The state of this component.
    var state: OTPComponentState { get set }

}

/**
 OTP Producer Status
 
 Stores the status of an `OTPProducer`, including its name, state (online/offline) and errors.
 
 Used by implementors for displaying information about discovered Producers.

*/

public struct OTPProducerStatus: OTPComponentStatus {
    
    /// A globally unique identifier (UUID) representing the producer, compliant with RFC 4122.
    public let cid: UUID
    
    /// A human-readable name for the producer.
    public var name: String
    
    /// The IP mode of the producer.
    public var ipMode: OTPIPMode
    
    /// The IP addresses of the producer.
    public var ipAddresses: [String]
    
    /// The number of sequence errors in advertisement messages from the producer.
    public var sequenceErrors: Int
    
    /// The status of this producer.
    public var state: OTPComponentState
    
    /**
     Creates a new OTP Producer Status.
    
     Includes identifying and status information.

     - Parameters:
        - name: The human-readable name of this Producer.
        - cid: The CID of this Producer.
        - ipMode: The IP mode of this Producer.
        - ipAddresses: The IP Addresses of this Producer.
        - sequenceErrors: The number of sequence errors from this Producer.
        - state: The state of this Producer.
        - online: Optional: Whether this Producer is considered online.

    */
    public init(name: String, cid: UUID, ipMode: OTPIPMode, ipAddresses: [String], sequenceErrors: Int, state: OTPComponentState) {
        self.cid = cid
        self.name = name
        self.ipMode = ipMode
        self.ipAddresses = ipAddresses
        self.sequenceErrors = sequenceErrors
        self.state = state
    }
    
}

/**
 OTP Consumer Status
 
 Stores the status of an `OTPConsumer`, including its name, state (online/offline) and errors.

 Used by implementors for displaying information about discovered Consumers.

*/

public struct OTPConsumerStatus: OTPComponentStatus {
    
    /// A globally unique identifier (UUID) representing the consumer, compliant with RFC 4122.
    public let cid: UUID
    
    /// A human-readable name for the consumer.
    public var name: String
    
    /// The IP mode of the producer.
    public var ipMode: OTPIPMode
    
    /// The IP addresses of the consumer.
    public var ipAddresses: [String]
    
    /// The number of sequence errors in advertisement messages from the consumer.
    public var sequenceErrors: Int
    
    /// The state of this consumer.
    public var state: OTPComponentState
    
    /// A list of the module identifiers supported by this consumer.
    public var supportedModuleIdentifiers: [String]
    
    /**
     Creates a new OTP Consumer Status.
    
     Includes identifying and status information.

     - Parameters:
        - name: The human-readable name of this Consumer.
        - cid: The CID of this Consumer.
        - ipMode: The IP mode of this Consumer.
        - ipAddresses: The IP Addresses of this Consumer.
        - sequenceErrors: The number of sequence errors from this Consumer.
        - state: The state of this Consumer.
        - moduleIdentifiers: The supported module identifiers of this Consumer.

    */
    public init(name: String, cid: UUID, ipMode: OTPIPMode, ipAddresses: [String], sequenceErrors: Int, state: OTPComponentState, moduleIdentifiers: [OTPModuleIdentifier]) {
        self.cid = cid
        self.name = name
        self.ipMode = ipMode
        self.ipAddresses = ipAddresses
        self.sequenceErrors = sequenceErrors
        self.state = state
        self.supportedModuleIdentifiers = moduleIdentifiers.map { "\($0.logDescription)" }
    }
    
}
