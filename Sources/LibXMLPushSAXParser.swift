//
//  LibXMLPushSAXParser.swift
//
//  Created by Robert Thompson on 8/7/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import Foundation

public enum PushSaxParserErrorCode: ErrorType {
    case LibXML2Error(message: String)
    case UsedAfterFinished
}

public struct LibXMLAttribute: Equatable {
    public let localName: String
    public let prefix: String?
    public let URI: String?
    public let value: String
    
    public init(localName: String = "", prefix: String? = nil, URI: String? = nil, value: String = "") {
        self.localName = localName
        self.prefix = prefix
        self.URI = URI
        self.value = value
    }
}

public func ==(lhs: LibXMLAttribute, rhs: LibXMLAttribute) -> Bool {
    return lhs.localName == rhs.localName &&
        lhs.prefix == rhs.prefix &&
        lhs.URI == rhs.URI &&
        lhs.value == rhs.value
}

/// A parser built on libxml2's SAX parsing.
///
/// Calling code must call either: 
/// - `_parse` exactly once, or
/// - `_parseData` any number of times and then `_finishParsing` exactly once.
public class LibXMLPushSAXParser {
    private let unsafeSelf = UnsafeMutablePointer<LibXMLPushSAXParser>.alloc(1)
    private var context: xmlParserCtxtPtr = nil
    private var error: ErrorType?
    
    internal init() {
        unsafeSelf.initialize(self)
        self.context = xmlCreatePushParserCtxt(&XMLPushSAXParserHandlerStruct,
            unsafeSelf,
            nil,
            0,
            nil)
    }
    
    internal func _parse(data: NSData) throws -> Void {
        guard self.context != nil else { throw PushSaxParserErrorCode.UsedAfterFinished }
        try _parseData(data)
        try _finishParsing()
    }
    
    internal func _parseData(data: NSData) throws -> Void {
        guard self.context != nil else { throw PushSaxParserErrorCode.UsedAfterFinished }
       
        xmlParseChunk(self.context, UnsafePointer<CChar>(data.bytes), Int32(data.length), 0)
        if let error = self.error {
            throw error
        }
    }
    
    internal func _finishParsing() throws -> Void {
        guard self.context != nil else { throw PushSaxParserErrorCode.UsedAfterFinished }

        xmlParseChunk(self.context, nil, 0, 1)
        cleanupContext()
        
        if let error = self.error {
            throw error
        }
    }
    
    func startElementWithPrefix(prefix: String?, URI: String?, localName: String, attributes: [String:LibXMLAttribute]) -> Void { fatalError("Subclass must implement") }
    func endElementWithPrefix(prefix: String?, URI: String?, localName: String) { fatalError("Subclass must implement") }
    func charactersFound(characters: UnsafePointer<Int8>, length: Int) { fatalError("Subclass must implement") }
    
    // The following method is dynamic because it gets called from an Objective-C function.
    dynamic func errorOccurred(message: String) {
        self.error = PushSaxParserErrorCode.LibXML2Error(message: message)
    }

    private var cleanupToken: dispatch_once_t = 0
    private func cleanupContext() {
        dispatch_once(&cleanupToken) {
            if self.context != nil {
                xmlFreeParserCtxt(self.context)
                self.unsafeSelf.destroy()
                self.context = nil
            }
        }
    }
    
    deinit {
        self.unsafeSelf.dealloc(1)
    }
}
