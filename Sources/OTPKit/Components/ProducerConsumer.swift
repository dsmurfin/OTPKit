//
//  ProducerConsumer.swift
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
 Producer Consumer
 
 Stores information about an `OTPConsumer` which has been received by an `OTPProducer`.
 
 Includes identifying information, folio numbers, state, errors and advertised data.

*/

struct ProducerConsumer: Equatable {
    
    /// A globally unique identifier (UUID) representing the consumer, compliant with RFC 4122.
    var cid: CID
    
    /// The human-readable name of the consumer.
    var name: ComponentName
    
    /// The ip address of the consumer.
    var ipAddress: String
    
    /// The last system advertisement folio number received from this consumer.
    var systemAdvertisementFolio: FolioNumber?
    
    /// The last name advertisement folio number received from this consumer.
    var nameAdvertisementFolio: FolioNumber?
    
    /// The last name advertisement page received from this consumer.
    var nameAdvertisementPage: Page?
    
    /// The last module advertisement folio number received from this consumer.
    var moduleAdvertisementFolio: FolioNumber?
    
    /// The last module advertisement page received from this consumer.
    var moduleAdvertisementPage: Page?
    
    /// The last time a advertisement message was received.
    var receivedAdvertisement: Date?
    
    /// The most recent notified state of this consumer.
    var notifiedState: OTPComponentState
    
    /// The count of sequence errors from this consumer.
    var sequenceErrors: Int
    
    /// The module identifiers advertised by the consumer.
    var moduleIdentifiers: [OTPModuleIdentifier]

    /**
     Initializes a new Producer Consumer when it is first discovered by a system advertisement message.

     - Parameters:
        - cid: The CID of the Consumer.
        - name: The human-readable name of the Consumer.
        - ipAddress: The IP Address of the Producer.
        - systemAdvertisementFolio: The System Advertisement folio number received from the Consumer.

    */
    init(cid: CID, name: ComponentName, ipAddress: String, systemAdvertisementFolio: FolioNumber) {
        self.cid = cid
        self.name = name
        self.ipAddress = ipAddress
        self.systemAdvertisementFolio = systemAdvertisementFolio
        self.moduleIdentifiers = []
        self.receivedAdvertisement = Date()
        self.notifiedState = .advertising
        self.sequenceErrors = 0
    }
    
    /**
     Initializes a new Producer Consumer when it is first discovered by a name advertisement message.

     - Parameters:
        - cid: The CID of the Consumer.
        - name: The human-readable name of the Consumer.
        - ipAddress: The IP Address of the Producer.
        - nameAdvertisementFolio: The Name Advertisement folio number received from the Consumer.
        - nameAdvertisementPage: The Name Advertisement page received from the Consumer.

    */
    init(cid: CID, name: ComponentName, ipAddress: String, nameAdvertisementFolio: FolioNumber, nameAdvertisementPage: Page) {
        self.cid = cid
        self.name = name
        self.ipAddress = ipAddress
        self.nameAdvertisementFolio = nameAdvertisementFolio
        self.nameAdvertisementPage = nameAdvertisementPage
        self.moduleIdentifiers = []
        self.receivedAdvertisement = Date()
        self.notifiedState = .advertising
        self.sequenceErrors = 0
    }
    
    /**
     Initializes a new Producer Consumer when it is first discovered by a module advertisement message.

     - Parameters:
        - cid: The CID of the Consumer.
        - name: The human-readable name of the Consumer.
        - ipAddress: The IP Address of the Producer.
        - moduleAdvertisementFolio: The Module Advertisement folio number received from the Consumer.
        - moduleAdvertisementPage: The Module Advertisement page received from the Consumer.
        - moduleIdentifiers: The Module Identifiers received from the Consumer.

    */
    init(cid: CID, name: ComponentName, ipAddress: String, moduleAdvertisementFolio: FolioNumber, moduleAdvertisementPage: Page, moduleIdentifiers: [OTPModuleIdentifier]) {
        self.cid = cid
        self.name = name
        self.ipAddress = ipAddress
        self.moduleAdvertisementFolio = moduleAdvertisementFolio
        self.moduleAdvertisementPage = moduleAdvertisementPage
        self.moduleIdentifiers = moduleIdentifiers
        self.receivedAdvertisement = Date()
        self.notifiedState = .advertising
        self.sequenceErrors = 0
    }
    
    /// Whether this Consumer should switch to be offline.
    var shouldGoOffline: Bool {
                
        switch notifiedState {
        case .offline:
            
            // this producer is already offline
            return false
            
        case .advertising, .online:
            
            guard let receivedAdvertisement = self.receivedAdvertisement else { return false }
            
            let now = Date()
            
            // if the last 2 module advertisement messages have not been received, then this consumer should go offline
            return Milliseconds(now.timeIntervalSince(receivedAdvertisement) * 1000) >= ModuleAdvertismentLayer.Timing.interval.rawValue * 2
            
        }

    }
    
    /**
     Producer Consumer `Equatable`
     
     - Parameters:
        - lhs: The first instance to be compared.
        - rhs: The second instance to be compared.
     
     - Returns: Whether the instances are considered equal.
     
    */
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.cid == rhs.cid
    }
    
}
