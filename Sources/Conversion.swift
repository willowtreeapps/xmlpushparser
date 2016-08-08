//
//  Conversion.swift
//
//  Created by Ian Terrell on 7/22/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import Foundation

public class Conversion {
    public static func stringFromData(data: NSData) -> String {
        guard let string = NSString(data: data, encoding: NSUTF8StringEncoding) else {
            return ""
        }
        return string as String
    }
    
    public static func intFromString(string: String?) -> Int? {
        guard let string = string else {
            return nil
        }
        guard let int = Int(string) else {
            return 0
        }
        return int
    }
    
    public static func boolFromString(string: String?) -> Bool? {
        guard let string = string else {
            return nil
        }
        switch string.lowercaseString {
        case "t", "true", "1":
            return true
        default:
            return false
        }
    }
}