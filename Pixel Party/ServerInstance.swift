//
//  URLGenerator.swift
//  Pixel Party
//
//  Created by Ryan Laughlin on 12/29/16.
//  Copyright © 2016 Ryan Laughlin. All rights reserved.
//

import Foundation

class ServerInstance {
    static var scoreboardUrl: String? {
        guard let baseUrl = baseUrl else {
            return nil
        }
        
        return "\(baseUrl)/scoreboard"
    }
    
    static var baseUrl: String? {
        guard let ipAddress = ipAddress else {
            return nil
        }
        
        return "http://\(ipAddress):\(ENV("Port")!)"
    }
    
    // Return IP address of WiFi interface (en0) as a String
    // via http://stackoverflow.com/questions/30748480/swift-get-devices-ip-address
    static var ipAddress: String? {
        var address : String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {
                    
                    // Convert interface address to a human readable string:
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    
}
