//
//  ConsumerProducer.swift
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
 Consumer Producer
 
 Stores information about an `OTPProducer` which has been received by an `OTPConsumer`.
 
 Includes identifying information, folio numbers, state, errors, advertised data and points.

*/

struct ConsumerProducer: Equatable {
    
    /// A globally unique identifier (UUID) representing the producer, compliant with RFC 4122.
    var cid: CID
    
    /// The human-readable name of the producer.
    var name: ComponentName
    
    /// The ip mode of the producer.
    var ipMode: OTPIPMode
    
    /// The ip addresses of the producer.
    var ipAddresses: [String]
    
    /// The last system advertisement folio number received from this producer.
    var systemAdvertisementFolio: FolioNumber?
    
    /// The last name advertisement folio number received from this producer.
    var nameAdvertisementFolio: FolioNumber?
    
    /// The last name advertisement page received from this producer.
    var nameAdvertisementPage: Page?
    
    /// A rolling window of folios received from this producer for every possible system of this producer 1-200 (accessed by index).
    var systemTransformFolios: [(systemNumber: SystemNumber, folios: [Folio])]
    
    /// The last time a transform message was received.
    var receivedTransform: Date?
    
    /// The last time a advertisement message was received.
    var receivedAdvertisement: Date?
    
    /// The most recent notified state of this producer. This flag is also used to determine whether to use this producer for data merges
    var notifiedState: OTPComponentState
    
    /// The count of sequence errors from this producer.
    var sequenceErrors: Int
    
    /// The system numbers being transmitted by this producer.
    var systemNumbers: [SystemNumber]
    
    /// Address point descriptions received from this producer.
    var addressPointDescriptions: [AddressPointDescription]

    /// The most recent full set of points received from this producer.
    var points: [ConsumerPoint]
    
    /**
     Initializes a new Consumer Producer when it is first discovered by a system advertisement message.

     - Parameters:
        - cid: The CID of the Producer.
        - name: The human-readable name of the Producer.
        - ipMode: The `OTPIPMode` of the Producer.
        - ipAddress: The IP Address of the Producer.
        - systemAdvertisementFolio: A System Advertisement folio number received from the Producer.
        - systemNumbers: The System Numbers being transmitted by the Producer.

    */
    init(cid: CID, name: ComponentName, ipMode: OTPIPMode, ipAddress: String, systemAdvertisementFolio: FolioNumber, systemNumbers: [SystemNumber]) {
        self.cid = cid
        self.name = name
        self.ipMode = ipMode
        self.ipAddresses = [ipAddress]
        self.systemAdvertisementFolio = systemAdvertisementFolio
        self.addressPointDescriptions = []
        self.systemNumbers = systemNumbers
        self.systemTransformFolios = (SystemNumber.minSystemNumber...SystemNumber.maxSystemNumber).map { (systemNumber: $0, folios: []) }
        self.points = []
        self.receivedAdvertisement = Date()
        self.notifiedState = .advertising
        self.sequenceErrors = 0
    }
    
    /**
     Initializes a new Consumer Producer when it is first discovered by a name advertisement message.

     - Parameters:
        - cid: The CID of the Producer.
        - name: The human-readable name of the Producer.
        - ipMode: The `OTPIPMode` of the Producer.
        - ipAddress: The IP Address of the Producer.
        - nameAdvertisementFolio: A Name Advertisement folio number received from the Producer.
        - nameAdvertisementPage: A Name Advertisement page received from the Producer.
        - addressPointDescriptions: The Address Point Descriptions provided by the Producer.

    */
    init(cid: CID, name: ComponentName, ipMode: OTPIPMode, ipAddress: String, nameAdvertisementFolio: FolioNumber, nameAdvertisementPage: Page, addressPointDescriptions: [AddressPointDescription]) {
        self.cid = cid
        self.name = name
        self.ipMode = ipMode
        self.ipAddresses = [ipAddress]
        self.nameAdvertisementFolio = nameAdvertisementFolio
        self.nameAdvertisementPage = nameAdvertisementPage
        self.addressPointDescriptions = addressPointDescriptions
        self.systemNumbers = []
        self.systemTransformFolios = (SystemNumber.minSystemNumber...SystemNumber.maxSystemNumber).map { (systemNumber: $0, folios: []) }
        self.points = []
        self.receivedAdvertisement = Date()
        self.notifiedState = .advertising
        self.sequenceErrors = 0
    }
    
    /**
     Initializes a new Consumer Producer when it is first discovered by a transform message.

     - Parameters:
        - cid: The CID of the Producer.
        - name: The human-readable name of the Producer.
        - ipMode: The `OTPIPMode` of the Producer.
        - ipAddress: The IP Address of the Producer.
     
    */
    init(cid: CID, name: ComponentName, ipMode: OTPIPMode, ipAddress: String) {
        self.cid = cid
        self.name = name
        self.ipMode = ipMode
        self.ipAddresses = [ipAddress]
        self.systemTransformFolios = (SystemNumber.minSystemNumber...SystemNumber.maxSystemNumber).map { (systemNumber: $0, folios: []) }
        self.addressPointDescriptions = []
        self.systemNumbers = []
        self.points = []
        self.receivedTransform = Date()
        self.receivedAdvertisement = Date()
        self.notifiedState = .online
        self.sequenceErrors = 0
    }
    
    /// Whether this Producer should switch to be offline.
    var shouldGoOffline: Bool {
        
        let now = Date()
        
        switch notifiedState {
        case .offline:
            
            // this producer is already offline
            return false
            
        case .advertising:
            
            guard let receivedAdvertisement = self.receivedAdvertisement else { return false }
            
            // if no advertisement messages have been received for 60 seconds, this producer should go offline
            return Milliseconds(now.timeIntervalSince(receivedAdvertisement) * 1000) >= 60000
            
        case .online:
            
            guard let receivedTransform = self.receivedTransform else { return false }

            // if the last transform message was more than the data loss timeout this producer should go offline
            return Milliseconds(now.timeIntervalSince(receivedTransform) * 1000) >= TransformLayer.Timing.dataLossTimeout.rawValue
            
        }
        
    }
    
    /**
     Updates the time a Transform message was received to now.
    */
    mutating func transformMessageReceived() {
        self.receivedTransform = Date()
        self.notifiedState = .online
    }
    
    /**
     Adds Address Point Descriptions to this Producer, replacing existing ones and adding additional.

     - Parameters:
        - addressPointDescriptions: The Address Point Descriptions provided by the Producer.

    */
    mutating func addingAddressPointDescriptions(_ addressPointDescriptions: [AddressPointDescription]) {

        // uniquely addressed address point descriptions, keeping newly provided over existing
        let newAddressPointDescriptions = Set(addressPointDescriptions).union(self.addressPointDescriptions)

        self.addressPointDescriptions = Array(newAddressPointDescriptions)
        
        // loop through all points and update the name
        for (index, point) in self.points.enumerated() {
            
            // a name must exist for this point and it must be different to the current one
            guard let name = self.addressPointDescriptions.first(where: { $0.address == point.address })?.pointName, name != point.name else { continue }
            
            // update this point name
            self.points[index].name = name
            
        }
        
    }
    
    /**
     Consumer Producer `Equatable`
     
     - Parameters:
        - lhs: The first instance to be compared.
        - rhs: The second instance to be compared.
     
     - Returns: Whether the instances are considered equal.
     
    */
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.cid == rhs.cid
    }
    
}
