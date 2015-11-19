//
//  Reachability.swift
//  JSONTechTest
//
//  Created by Ronald Fischer on 11/15/15.
//  Copyright © 2015 qpiapps. All rights reserved.
//

import Foundation
import SystemConfiguration

// Not convinced that this is reliable.  Is failing in simulator when internet is present...
public class Reachability {
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, UnsafePointer($0))
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
//        print(".TransientConnection \(flags  ==  .TransientConnection)")
//        print(".Reachable \(flags  ==  .Reachable)")
//        print(".ConnectionRequired \(flags  ==  .ConnectionRequired)")
//        print(".ConnectionOnTraffic \(flags  ==  .ConnectionOnTraffic)")
//        print(".InterventionRequired \(flags  ==  .InterventionRequired)")
//        print(".ConnectionOnDemand \(flags  ==  .ConnectionOnDemand)")
//        print(".IsLocalAddress \(flags  ==  .IsLocalAddress)")
//        print(".IsDirect \(flags  ==  .IsDirect)")
//        print(".IsWWAN \(flags  ==  .IsWWAN)")
//        print(".ConnectionAutomatic \(flags  ==  .ConnectionAutomatic)")
        
        let isReachable = flags == .Reachable
        let needsConnection = flags == .ConnectionRequired
        
        return isReachable && !needsConnection
        
    }
}