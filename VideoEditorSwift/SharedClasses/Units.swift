//
//  Units.swift
//  sinefa
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import Foundation

public struct Units {
    
    public let bytes: Double
    
    public var kilobytes: Double {
        return Double(bytes) / 1_024
    }
    
    public var megabytes: Double {
        return kilobytes / 1_024
    }
    
    public var gigabytes: Double {
        return megabytes / 1_024
    }
    
    public init(bytes: Double) {
        self.bytes = bytes
    }
    
    public func getReadableUnit() -> String {
        
        switch bytes {
        case 0..<1_024:
            return "\(String(format: "%.2f", bytes)) bytes"
//            return "\(bytes) bytes"
        case 1_024..<(1_024 * 1_024):
            return "\(String(format: "%.2f", kilobytes)) kb"
        case 1_024..<(1_024 * 1_024 * 1_024):
            return "\(String(format: "%.2f", megabytes)) mb"
        case (1_024 * 1_024 * 1_024)...Double.greatestFiniteMagnitude:
            return "\(String(format: "%.2f", gigabytes)) gb"
        default:
            return "\(bytes) bytes"
        }
    }

    public func getReadableKsUnit() -> String {
        
        switch bytes {
        case 0..<1_024:
            return "\(String(format: "%.2f", bytes))"
        //            return "\(bytes) bytes"
        case 1_024..<(1_024 * 1_024):
            return "\(String(format: "%.2f", kilobytes)) k"
        case 1_024..<(1_024 * 1_024 * 1_024):
            return "\(String(format: "%.2f", megabytes)) m"
        case (1_024 * 1_024 * 1_024)...Double.greatestFiniteMagnitude:
            return "\(String(format: "%.2f", gigabytes)) b"
        default:
            return "\(bytes)"
        }
    }
}
