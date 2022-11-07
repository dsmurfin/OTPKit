//
//  Component.swift
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
import CocoaAsyncSocket

/// A type used for the universally unique identifier of a`Component`. This must be compliant with RFC 4122.
typealias CID = UUID

/// A type used for the human-readable name of a `Component`.
typealias ComponentName = String

/**
 Component Name Extension
 
 Extensions to `ComponentName`.

*/

extension ComponentName {
    
    /// The maximum size of a `ComponentName` in bytes.
    static let maxComponentNameBytes: Int = 32
    
}

// MARK: -
// MARK: -

/**
 OTP Component
 
 All `OTPConsumer`s and `OTPProducer`s are OTP Components.
 
 The core requirements of an OTP Component.

*/

protocol Component: AnyObject {
    
    /// The dispatch queue used for read/write operations.
    static var queue: DispatchQueue { get }
    
    /// The dispatch queue on which socket notifications occur.
    static var socketDelegateQueue: DispatchQueue { get }
    
    // MARK: General

    /// A globally unique identifier (UUID) representing the component, compliant with RFC 4122.
    var cid: CID { get }
    
    /// A human-readable name for the component.
    var name: ComponentName { get set }
    
    /// The Internet Protocol version(s) used by the component.
    var ipMode: OTPIPMode { get }
    
    /// The `name` of the component stored as `Data`.
    var nameData: Data { get set }
    
    // MARK: Socket
    
    /// The interface for communications.
    var interface: String? { get }
    
    /// The socket used for unicast communications.
    var unicastSocket: ComponentSocket { get }
    
    /// The socket used for multicast IPv4 communications.
    var multicast4Socket: ComponentSocket? { get }
    
    /// The socket used for multicast IPv6 communications.
    var multicast6Socket: ComponentSocket? { get }
    
    /// Whether the component is able to send/receive data.
    var isConnected: Bool { get }
    
    // MARK: Delegate
    
    /// The delegate which receives protocol error notifications from this component.
    var protocolErrorDelegate: OTPComponentProtocolErrorDelegate? { get set }
    
    /// The delegate which receives debug log messages from this component.
    var debugDelegate: OTPComponentDebugDelegate? { get set }

    /// The dispatch queue on which to send delegate notifications.
    var delegateQueue: DispatchQueue { get }
    
    // MARK: Timer
    
    /// The dispatch queue on which timers run.
    var timerQueue: DispatchQueue { get }
    
    // MARK: System Advertisement
    
    /// The system advertisement timer.
    var systemAdvertisementTimer: DispatchSourceTimer? { get set }
    
    /// The system numbers being transmitted (`OTPProducer`) OR being received in advertisement messages (`OTPConsumer`)
    var systemNumbers: [SystemNumber] { get set }
    
    /// A pre-compiled system advertisement message.
    var systemAdvertisementMessage: Data? { get set }
    
    /// The last transmitted system advertisement folio number for this component.
    var systemAdvertisementFolio: FolioNumber { get set }
    
    // MARK: Name Advertisement

    /// The name advertisement timer.
    var nameAdvertisementTimer: DispatchSourceTimer? { get set }
    
    /// A pre-compiled array of name advertisement messages.
    var nameAdvertisementMessages: [Data] { get set }
    
    /// The last transmitted name advertisement folio number for this component.
    var nameAdvertisementFolio: FolioNumber { get set }

    // MARK: Module Advertisement

    /// The module advertisement timer.
    var moduleAdvertisementTimer: DispatchSourceTimer? { get set }
    
    /**
     Starts this Component.
     
     When started, this Component will begin transmitting and listening for OTP Messages.
     
     - Throws: An error of type `ComponentSocketError`.

    */
    func start() throws
    
    /**
     Stops this Component.
     
     When stopped, this Component will no longer transmit or listen for OTP Messages.
     
    */
    func stop()
    
    /**
     Updates the human-readable name of this Component.
     
     - Parameters:
        - name: A human-readable name for this component.
     
    */
    func update(name: String)
    
}

// MARK: -
// MARK: -

/**
 Component Extension
 
 Extensions to `Component` inherited by all implementors of the protocol.

*/

extension Component {
        
    /**
     Builds the Name Data object for this Component.
     
     - Returns: A Data object.

    */
    func buildNameData() -> Data {
        self.name.data(paddedTo: ComponentName.maxComponentNameBytes)
    }
    
    /**
     Builds the System Advertisement Message for this Component.

     - Returns: An optional Data object.

    */
    func buildSystemAdvertisementMessage() -> Data? {
        
        let request = (self as? OTPConsumer) != nil ? true : false
        
        let cid = Self.queue.sync { self.cid }
        let nameData = Self.queue.sync { self.nameData }
        let componentSystemNumbers = Self.queue.sync { self.systemNumbers }
        
        // system advertisement messages must either be a consumer request or have at least 1 system number
        guard request || componentSystemNumbers.count > 0 else { return nil }

        // layers
        var otpLayerData = OTPLayer.createAsData(with: .advertisementMessage, cid: cid, nameData: nameData)
        var advertisementLayerData = AdvertismentLayer.createAsData(with: .system)
        var systemAdvertisementLayerData = request ? SystemAdvertismentLayer.createAsData(with: .systemList) : SystemAdvertismentLayer.createAsData(with: .systemList, systemNumbers: systemNumbers)
        
        // calculate and insert system advertisement layer length
        let systemAdvertisementLayerLength: OTPPDULength = OTPPDULength(systemAdvertisementLayerData.count - SystemAdvertismentLayer.lengthCountOffset)
        systemAdvertisementLayerData.replacingPDULength(systemAdvertisementLayerLength, at: SystemAdvertismentLayer.Offset.length.rawValue)

        // calculate and insert advertisement layer length
        let advertisementLayerLength: OTPPDULength = OTPPDULength(advertisementLayerData.count + systemAdvertisementLayerData.count - AdvertismentLayer.lengthCountOffset)
        advertisementLayerData.replacingPDULength(advertisementLayerLength, at: AdvertismentLayer.Offset.length.rawValue)

        // calculate and insert otp layer length
        let otptLayerLength: OTPPDULength = OTPPDULength(otpLayerData.count + advertisementLayerData.count + systemAdvertisementLayerData.count - OTPLayer.lengthCountOffset)
        otpLayerData.replacingPDULength(otptLayerLength, at: OTPLayer.Offset.length.rawValue)
        
        return otpLayerData + advertisementLayerData + systemAdvertisementLayerData
        
    }
    
    /**
     Builds the Name Advertisement Messages for this Component.

     - Returns: An optional Data object.

    */
    func buildNameAdvertisementMessages() -> [Data] {
                
        let request = (self as? OTPConsumer) != nil ? true : false
        
        let cid = Self.queue.sync { self.cid }
        let nameData = Self.queue.sync { self.nameData }
        let addressPointDescriptions = Self.queue.sync { (self as? OTPProducer)?.nameAddressPointDescriptions }
        
        if request {
            
            // layers
            var otpLayerData = OTPLayer.createAsData(with: .advertisementMessage, cid: cid, nameData: nameData)
            var advertisementLayerData = AdvertismentLayer.createAsData(with: .name)
            var nameAdvertisementLayerData = NameAdvertismentLayer.createAsData(with: .nameList)
            
            // calculate and insert name advertisement layer length
            let nameAdvertisementLayerLength: OTPPDULength = OTPPDULength(nameAdvertisementLayerData.count - NameAdvertismentLayer.lengthCountOffset)
            nameAdvertisementLayerData.replacingPDULength(nameAdvertisementLayerLength, at: NameAdvertismentLayer.Offset.length.rawValue)

            // calculate and insert advertisement layer length
            let advertisementLayerLength: OTPPDULength = OTPPDULength(advertisementLayerData.count + nameAdvertisementLayerData.count - AdvertismentLayer.lengthCountOffset)
            advertisementLayerData.replacingPDULength(advertisementLayerLength, at: AdvertismentLayer.Offset.length.rawValue)

            // calculate and insert otp layer length
            let otpLayerLength: OTPPDULength = OTPPDULength(otpLayerData.count + advertisementLayerData.count + nameAdvertisementLayerData.count - OTPLayer.lengthCountOffset)
            otpLayerData.replacingPDULength(otpLayerLength, at: OTPLayer.Offset.length.rawValue)

            return [otpLayerData + advertisementLayerData + nameAdvertisementLayerData]
            
        } else {
            
            // must be able to get address point descriptions
            guard let addressPointDescriptions = addressPointDescriptions else { return [] }
            
            let adpCount = addressPointDescriptions.count
            let adpMax = NameAdvertismentLayer.maxMessageAddressPointDescriptions
            
            // how many pages are required (must be capped at max pages even if more exist)?
            let pageCount = min((adpCount / adpMax) + (adpCount % adpMax == 0 ? 0 : 1 ), Int(Page.max))

            var pages = [Data]()

            // loop through each page
            for page in 0..<pageCount {
                
                let first = page*adpMax
                let last = min(first+adpMax, adpCount)

                // the address point descriptions for this page
                let pageAddressPointDescriptions = Array(addressPointDescriptions[first..<last])
                
                // layers
                var otpLayerData = OTPLayer.createAsData(with: .advertisementMessage, cid: cid, nameData: nameData, page: Page(page), lastPage: Page(pageCount-1))
                var advertisementLayerData = AdvertismentLayer.createAsData(with: .name)
                var nameAdvertisementLayerData = NameAdvertismentLayer.createAsData(with: .nameList, addressPointDescriptions: pageAddressPointDescriptions)
                
                // calculate and insert name advertisement layer length
                let nameAdvertisementLayerLength: OTPPDULength = OTPPDULength(nameAdvertisementLayerData.count - NameAdvertismentLayer.lengthCountOffset)
                nameAdvertisementLayerData.replacingPDULength(nameAdvertisementLayerLength, at: NameAdvertismentLayer.Offset.length.rawValue)

                // calculate and insert advertisement layer length
                let advertisementLayerLength: OTPPDULength = OTPPDULength(advertisementLayerData.count + nameAdvertisementLayerData.count - AdvertismentLayer.lengthCountOffset)
                advertisementLayerData.replacingPDULength(advertisementLayerLength, at: AdvertismentLayer.Offset.length.rawValue)

                // calculate and insert otp layer length
                let otpLayerLength: OTPPDULength = OTPPDULength(otpLayerData.count + advertisementLayerData.count + nameAdvertisementLayerData.count - OTPLayer.lengthCountOffset)
                otpLayerData.replacingPDULength(otpLayerLength, at: OTPLayer.Offset.length.rawValue)

                pages.append(otpLayerData + advertisementLayerData + nameAdvertisementLayerData)
                
            }

            return pages
            
        }
 
    }
    
    /**
     Sends a System Advertisement Message for this Component.
     
     - Parameters:
        - destination: The destination hostname and port of the message.
     
    */
    func sendSystemAdvertisementMessage(to destination: (host: Hostname, port: UDPPort)? = nil) {

        let systemAdvertisementMessage = Self.queue.sync { self.systemAdvertisementMessage }

        guard var messageData = systemAdvertisementMessage else { return }

        // get the folio number and replace it in the message
        let folioNumber = Self.queue.sync { self.systemAdvertisementFolio }
        
        messageData.replacingOTPLayerFolio(with: folioNumber)

        // send the message(s)
        if let destination = destination {
            
            unicastSocket.send(message: messageData, host: destination.host, port: destination.port)
            
            // notify the debug delegate
            delegateQueue.async { self.debugDelegate?.debugLog("Sending system advertisement message to \(destination.host):\(destination.port) \(messageData.count)") }
            
        } else {
            
            if ipMode.usesIPv4() {
                unicastSocket.send(message: messageData, host: IPv4.advertisementMessageHostname, port: UDP.otpPort)
            }
            if ipMode.usesIPv6() {
                unicastSocket.send(message: messageData, host: IPv6.advertisementMessageHostname, port: UDP.otpPort)
            }
            
            // notify the debug delegate
            delegateQueue.async { self.debugDelegate?.debugLog("Sending system advertisement message to multicast") }
            
        }
        
        // increment the folio number
        Self.queue.sync(flags: .barrier) {
            self.systemAdvertisementFolio &+= 1
        }
                
    }
    
    /**
     Sends the Name Advertisement Messages for this Component.
     
     - Parameters:
        - destination: The destination hostname and port of the message.
     
    */
    func sendNameAdvertisementMessages(to destination: (host: Hostname, port: UDPPort)? = nil) {
        
        let nameAdvertisementMessages = Self.queue.sync { self.nameAdvertisementMessages }
        
        guard !nameAdvertisementMessages.isEmpty else { return }
        
        // get the folio number
        let folioNumber = Self.queue.sync { self.nameAdvertisementFolio }

        // loop through all messages
        for message in nameAdvertisementMessages {
            
            var messageData = message

            messageData.replacingOTPLayerFolio(with: folioNumber)

            // send the message(s)
            if let destination = destination {
                unicastSocket.send(message: messageData, host: destination.host, port: destination.port)
                
            } else {
                if ipMode.usesIPv4() {
                    unicastSocket.send(message: messageData, host: IPv4.advertisementMessageHostname, port: UDP.otpPort)
                }
                if ipMode.usesIPv6() {
                    unicastSocket.send(message: messageData, host: IPv6.advertisementMessageHostname, port: UDP.otpPort)
                }
            }
            
        }
        
        if let destination = destination {
        
            // notify the debug delegate
            delegateQueue.async { self.debugDelegate?.debugLog("Sending name advertisement message(s) to \(destination.host):\(destination.port)") }
            
        } else {
            
            // notify the debug delegate
            delegateQueue.async { self.debugDelegate?.debugLog("Sending name advertisement message(s) to multicast") }
            
        }
        
        // increment the folio number
        Self.queue.sync(flags: .barrier) {
            self.nameAdvertisementFolio &+= 1
        }
                
    }
    
}

// MARK: -
// MARK: -

/**
 OTP Component Protocol Error Delegate
 
 Required methods for objects implementing this delegate.

*/

public protocol OTPComponentProtocolErrorDelegate: AnyObject {
    
    /**
     Notifies the delegate of errors in parsing layers.
     
     - Parameters:
        - errorDescription: A human-readable description of the error.
     
    */
    func layerError(_ errorDescription: String)
    
    /**
     Notifies the delegate of sequence errors.
     
     - Parameters:
        - errorDescription: A human-readable description of the error.
     
    */
    func sequenceError(_ errorDescription: String)
    
    /**
     Notifies the delegate of unknown errors.
     
     - Parameters:
        - errorDescription: A human-readable description of the error.
     
    */
    func unknownError(_ errorDescription: String)
    
}

// MARK: -
// MARK: -

/**
 OTP Component Debug Delegate
 
 Required methods for objects implementing this delegate.

*/

public protocol OTPComponentDebugDelegate: AnyObject {
    
    /**
     Notifies the delegate of a new debug log entry.
     
     - Parameters:
        - logMessage: A human-readable log message.
     
    */
    func debugLog(_ logMessage: String)
    
    /**
     Notifies the delegate of a new socket debug log entry.
     
     - Parameters:
        - logMessage: A human-readable log message.
     
    */
    func debugSocketLog(_ logMessage: String)
    
}
