//
//  TestHelpers.swift
//  Salix
//
//  Created by Ian Terrell on 7/15/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import Foundation

class TestBundleClass {
    
}

func newTmpFile() -> NSURL {
    let tmpDir = NSURL(fileURLWithPath: NSTemporaryDirectory())
    return tmpDir.URLByAppendingPathComponent(NSUUID().UUIDString)
}

func fileNamed(name: String, ofType type: String) -> NSData? {
    let bundle = NSBundle(forClass: TestBundleClass.self)
    if let path = bundle.pathForResource(name, ofType: type) {
        return NSData(contentsOfFile: path)
    }
    return nil
}

func urlForFileNamed(name: String, ofType type: String) -> NSURL? {
    let bundle = NSBundle(forClass: TestBundleClass.self)
    if let path = bundle.pathForResource(name, ofType: type) {
        return NSURL(fileURLWithPath: path)
    }
    return nil
}