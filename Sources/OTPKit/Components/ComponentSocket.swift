//
//  ComponentSocket.swift
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
import Network

/**
 Component Socket Type
 
 Enumerates the types of component sockets.
 
*/

enum ComponentSocketType: String {
    
    /// Used for unicast communications (advertisement responses and transmitting to multicast)
    case unicast = "unicast"
    
    /// Used for IPv4 multicast communications (receiving advertisement and transform messages)
    case multicastv4 = "multicast V4"
    
    /// Used for IPv6 multicast communications (receiving advertisement and transform messages)
    case multicastv6 = "multicast V6"
    
}

/**
 Component Socket IP Family
 
 Enumerates the possible IP families.
 
 */
enum ComponentSocketIPFamily: String {
    
    /// IPv4.
    case IPv4 = "IPv4"
    
    /// IPv6.
    case IPv6 = "IPv6"
    
}

// MARK: -
// MARK: -

/**
 Component Socket
 
 Creates a raw socket for network communications, and handles delegate notifications.

*/

class ComponentSocket: NSObject, GCDAsyncUdpSocketDelegate {
 
    /// A globally unique identifier (UUID) representing a `Component`, compliant with RFC 4122.
    private var cid: UUID
    
    /// The raw socket.
    private var socket: GCDAsyncUdpSocket?
    
    /// The type of socket. `Components` implement a single `ComponentSocket` of each type.
    private var socketType: ComponentSocketType
    
    /// The dispatch queue on which the socket sends and receives messages.
    private var socketQueue: DispatchQueue
    
    /// The interface on which to bind this socket.
    private var interface: String
    
    /// The UDP port on which to bind this socket.
    private var port: UInt16
    
    /// The delegate to receive notifications.
    weak var delegate: ComponentSocketDelegate?
        
    /**
     Creates a new Component Socket.
     
     Component sockets are used for joining multicast groups, and sending and receiving network data.

     - Parameter cid: The CID of this Producer.
     - Parameter type: The type of socket (unicast, multicast IPV4, multicast IPv6).
     - Parameter port: Optional: UDP port to bind.
     - Parameter interface: The interface on which to bind the socket. It may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.4.35").
     - Parameter delegateQueue: The dispatch queue on which to receive delegate calls from this Producer.

    */
    init(cid: CID, type: ComponentSocketType, port: UDPPort = 0, interface: String, delegateQueue: DispatchQueue) {
        self.cid = cid
        self.socketType = type
        self.port = port
        self.interface = interface
        self.socketQueue = DispatchQueue(label: "com.danielmurfin.OTPKit.componentSocketQueue-\(cid.uuidString)")
        super.init()
        self.socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: delegateQueue, socketQueue: self.socketQueue)
    }
    
    /**
     Allows other services to reuse the port.
     
     - Throws: An error of type `ComponentSocketError`.
     
    */
    func enableReusePort() throws {
        do {
            try socket?.enableReusePort(true)
        } catch {
            throw ComponentSocketError.couldNotEnablePortReuse
        }
    }

    /**
     Attempts to join a multicast group.
     
     - Parameters:
        - multicastGroup: The multicast group hostname.

     - Throws: An error of type `ComponentSocketError`

    */
    func join(multicastGroup: Hostname) throws {
        
        switch socketType {
        case .unicast:
            break
        case .multicastv4, .multicastv6:
            do {
                try socket?.joinMulticastGroup(multicastGroup, onInterface: interface)
            } catch {
                throw ComponentSocketError.couldNotJoin(multicastGroup: multicastGroup)
            }
        }
        
    }
    
    /**
     Attempts to leave a multicast group.
     
     - Parameters:
        - multicastGroup: The multicast group hostname.

     - Throws: An error of type `ComponentSocketError`

    */
    func leave(multicastGroup: Hostname) throws {

        switch socketType {
        case .unicast:
            break
        case .multicastv4, .multicastv6:
            do {
                try socket?.leaveMulticastGroup(multicastGroup, onInterface: interface)
            } catch {
                throw ComponentSocketError.couldNotLeave(multicastGroup: multicastGroup)
            }
        }
        
    }

    /**
     Starts listening for network data. Binds sockets, and joins multicast groups as neccessary.
     
     - Parameters:
        - multicastGroups: An array of multicast group hostnames for this socket.

     - Throws: An error of type `ComponentSocketError`
     
    */
    func startListening(multicastGroups: [Hostname] = []) throws {

        // only bind on an interface if not multicast
        do {
            switch socketType {
            case .unicast:
                
                try socket?.bind(toPort: port, interface: interface)

                // notify the delegate
                delegate?.debugSocketLog("Successfully bound unicast to port: \(socket?.localPort() ?? 0) on interface: \(interface)")
                
            case .multicastv4, .multicastv6:
                
                try socket?.bind(toPort: port)
                
                // notify the delegate
                delegate?.debugSocketLog("Successfully bound multicast to port: \(port) on interface: \(interface)")
                
            }
        } catch {
            throw ComponentSocketError.couldNotBind(message: "\(cid): Could not bind \(socketType.rawValue) socket.")
        }
        
        // attempt to set the interface multicast should be sent on
        do {
            switch socketType {
            case .unicast:
                // try socket?.sendIPv4Multicast(onInterface: interface)
                try socket?.sendIPv6Multicast(onInterface: interface)
            case .multicastv4, .multicastv6:
                break
            }
        } catch {
            throw ComponentSocketError.couldNotAssignMulticastInterface(message: "\(cid): Could not assign interface(s) for sending multicast on \(socketType.rawValue) socket.")
        }
        
        // attempt to start receiving
        do {
            try socket?.beginReceiving()
        } catch {
            throw ComponentSocketError.couldNotReceive(message: "\(cid): Could not receive on \(socketType.rawValue) socket.")
        }
        
        // join multicast groups
        switch socketType {
        case .unicast:
            break
        case .multicastv4, .multicastv6:
            for group in multicastGroups {
                try join(multicastGroup: group)
            }
        }

    }
    
    /**
     Stops listening for network data.
     
     Closes this socket.
     
    */
    func stopListening() {
        socket?.close()
    }
    
    /**
     Sends a message to a specific host and port.
     
     - Parameters:
        - data: The data to be sent.
        - host: The destination hostname for this message.
        - port: The destination port for this message.

    */
    func send(message data: Data, host: Hostname, port: UDPPort) {
        socket?.send(data, toHost: host, port: port, withTimeout: -1, tag: 0)
    }
    
    /**
     Safely accesses the type of this socket and returns a string.
     
     - Returns: A string representing the type of this socket.
     
     */
    private func socketTypeString() -> String {
        var socketType = ComponentSocketType.unicast.rawValue
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.main.async {
            socketType = self.socketType.rawValue.capitalized
            semaphore.signal()
        }
        semaphore.wait()
        return socketType
    }
    
    // MARK: - GCD Async UDP Socket Delegate
    
    /**
     GCD Async UDP Socket Delegate
     
     Implements all required delegate methods for `GCDAsyncUdpSocket`.

    */
    
    /**
     Called when the datagram with the given tag has been sent.
    */
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        
        // notify the delegate
        delegate?.debugSocketLog("\(socketTypeString()) socket did send data")

    }
    
    /**
     Called if an error occurs while trying to send a datagram. This could be due to a timeout, or something more serious such as the data being too large to fit in a single packet.
    */
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        
        // notify the delegate
        delegate?.debugSocketLog("\(socketTypeString()) socket did not send data due to error \(String(describing: error?.localizedDescription))")
        
    }
    
    /**
     Called when the socket has received a datagram.
    */
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        
        // get the source hostname and port from the address
        guard let hostname = GCDAsyncUdpSocket.host(fromAddress: address) else { return }
        let port = GCDAsyncUdpSocket.port(fromAddress: address)
        let ipFamily: ComponentSocketIPFamily = GCDAsyncUdpSocket.family(fromAddress: address) == AF_INET6 ? .IPv6 : .IPv4
        
        // notify the delegate
        delegate?.debugSocketLog("Socket received data of length \(data.count), from \(ipFamily.rawValue) \(hostname):\(port)")

        // notify the delegate
        delegate?.receivedMessage(withData: data, sourceHostname: hostname, sourcePort: port, ipFamily: ipFamily)
        
    }
    
    /**
     Called when the socket is closed.
    */
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        
        // notify the delegate
        delegate?.debugSocketLog("\(socketTypeString()) socket did close, with error \(String(describing: error?.localizedDescription))")
        
    }
    
}

// MARK: -
// MARK: -

/**
 Component Socket Delegate
 
 Notifies observers when new messages are received, and provides debug information.
 
 Required methods for objects implementing this delegate.

*/

protocol ComponentSocketDelegate: AnyObject {
    
    /**
     Called when a message has been received.
     
     - Parameters:
        - data: The message as `Data`.
        - sourceHostname: The `Hostname` of the source of the message.
        - sourcePort: The `UDPPort` of the source of the message.
        - ipFamily: The `ComponentSocketIPFamily` of the source of the message.

    */
    func receivedMessage(withData data: Data, sourceHostname: Hostname, sourcePort: UDPPort, ipFamily: ComponentSocketIPFamily)
    
    /**
     Called when a debug socket log is produced.
     
     - Parameters:
        - logMessage: The debug message.

    */
    func debugSocketLog(_ logMessage: String)
    
}

// MARK: -
// MARK: -

/**
 Component Socket Error
 
 Enumerates all possible `ComponentSocketError` errors.
 
*/

public enum ComponentSocketError: LocalizedError {
    
    /// It was not possible to enable port reuse.
    case couldNotEnablePortReuse
    
    /// It was not possible to join this multicast group.
    case couldNotJoin(multicastGroup: String)
    
    /// It was not possible to leave this multicast group.
    case couldNotLeave(multicastGroup: String)
    
    /// It was not possible to bind to a port/interface.
    case couldNotBind(message: String)
    
    /// It was not possible to assign the interface on which to send multicast.
    case couldNotAssignMulticastInterface(message: String)
    
    /// It was not possible to start receiving data, e.g. because no bind occured first.
    case couldNotReceive(message: String)

    /**
     A human-readable description of the error useful for logging purposes.
    */
    public var logDescription: String {
        switch self {
        case .couldNotEnablePortReuse:
            return "Could not enable port reuse"
        case let .couldNotJoin(multicastGroup):
            return "Could not join multicast group \(multicastGroup)"
        case let .couldNotLeave(multicastGroup):
            return "Could not leave multicast group \(multicastGroup)"
        case let .couldNotBind(message), let .couldNotReceive(message), let .couldNotAssignMulticastInterface(message):
            return message
        }
    }
        
}
