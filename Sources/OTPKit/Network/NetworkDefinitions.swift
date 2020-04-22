//
//  NetworkDefinitions.swift
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

/// A type used for hostnames and IP addresses of network devices.
typealias Hostname = String

/// A type used for UDP port numbers.
typealias UDPPort = UInt16

/**
 UDP
 
 UDP related constants and definitions.

*/

struct UDP {
    
    /// The UDP port used by OTP for multicast transmission.
    static let otpPort: UInt16 = 5568
    
    /// The maximum permitted length of an OTP message over UDP.
    static let maxMessageLength: Int = 1472

}

/**
 IP Mode
 
 The Internet Protocol version used by a Component.
 
 - ipv4Only: Only use IPv4
 - ipv6Only: Only use IPv6
 - ipv4And6: Use IPv4 and IPv6

*/
public enum OTPIPMode: String, CaseIterable {
    
    /// The `Component` should only use IPv4.
    case ipv4Only = "OTP-4"
    
    /// The `Component` should only use IPv6.
    case ipv6Only = "OTP-6"
    
    /// The `Component` should use IPv4 and IPv6.
    case ipv4And6 = "OTP-4/6"
    
    /// An array of titles for all cases.
    public static var titles: [String] {
        Self.allCases.map (\.rawValue)
    }
    
    /// The title for this case.
    public var title: String {
        self.rawValue
    }
    
    /**
     Does this IP Mode use IPv4?
     
     - Returns: Whether this case includes IPv4.
     
    */
    internal func usesIPv4() -> Bool { self != .ipv6Only }
    
    /**
     Does this IP Mode use IPv6?
     
     - Returns: Whether this case includes IPv4.

    */
    internal func usesIPv6() -> Bool { self != .ipv4Only }

}

/**
 IPv4
 
 Contains IPv4 related constants and definitions.

*/

struct IPv4 {
    
    /// The prefix of the multicast address used by OTP for transform messages.
    private static var transformMessagePrefix: String = "239.159.1."
    
    /// The multicast address used by OTP for advertisement messages.
    static var advertisementMessageHostname: Hostname = "239.159.2.1"
    
    /**
    Attempts to calculate an IPv4 Hostname for a Transform Message with a certain System Number.
     
     - Parameters:
        - systemNumber: The `SystemNumber` for which to calculate the `Hostname`.
     
     - Returns: An optional `Hostname`.

    */
    static func transformHostname(for systemNumber: SystemNumber) -> Hostname? {
        SystemNumber.minSystemNumber...SystemNumber.maxSystemNumber ~= systemNumber ? "\(Self.transformMessagePrefix)\(systemNumber)" : nil
    }

}

/**
 IPv6
 
 Contains IPv6 related constants and definitions.

*/

struct IPv6 {
    
    /// The prefix of the multicast address used by OTP for transform messages.
    private static var transformMessagePrefix: String = "ff18::9f:00:01:"
    
    /// The multicast address used by OTP for advertisement messages.
    static var advertisementMessageHostname: Hostname = "ff18::9f:00:02:01"

    /**
    Attempts to calculate an IPv6 Hostname for a Transform Message with a certain System Number.
     
     - Parameters:
        - systemNumber: The `SystemNumber` for which to calculate the `Hostname`.
     
     - Returns: An optional `Hostname`.

    */
    static func transformHostname(for systemNumber: SystemNumber) -> Hostname? {
        SystemNumber.minSystemNumber...SystemNumber.maxSystemNumber ~= systemNumber ? "\(Self.transformMessagePrefix)\(String(format: "%02X", systemNumber))" : nil
    }

}
