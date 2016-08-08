//
//  XMLCallbackFunctions.swift
//
//  Created by Robert Thompson on 8/7/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import Foundation

// Some convenience computed properties on LibXMLRawAttribute
extension LibXMLRawAttribute: Equatable {
    
    var valueLength: Int {
        return valueEnd - valueStart
    }
    
    var localNameString: String {
        return String.fromCString(localName) ?? ""
    }
    
    var prefixString: String? {
        return String.fromCString(prefix)
    }
    
    var URIString: String? {
        return String.fromCString(URI)
    }
    
    var key: String {
       return (prefixString != nil ? prefixString! + ":" : "") + localNameString
    }
    
    var attributeValue: String {
        return (NSString(bytes: valueStart, length: valueLength, encoding: NSUTF8StringEncoding) as String?) ?? ""
    }
    
    static func getBufferPointerWithStart(start: UnsafePointer<Void>, length: Int) -> UnsafeBufferPointer<LibXMLRawAttribute> {
       return UnsafeBufferPointer<LibXMLRawAttribute>(start: UnsafePointer<LibXMLRawAttribute>(start), count: length)
    }
}

public func ==(lhs: LibXMLRawAttribute, rhs: LibXMLRawAttribute) -> Bool {
    return lhs.localName == rhs.localName &&
        lhs.prefix == rhs.prefix &&
        lhs.URI == rhs.URI &&
        lhs.valueStart == rhs.valueStart &&
        lhs.valueEnd == rhs.valueEnd
}

private extension LibXMLAttribute {
    init(rawValue: LibXMLRawAttribute) {
        self.prefix = rawValue.prefixString
        self.localName = rawValue.localNameString
        self.URI = rawValue.URIString
        self.value = rawValue.attributeValue
    }
}

private func XMLPushSAXParserStartElementSAX(ctx: UnsafeMutablePointer<Void>,
    localname: UnsafePointer<xmlChar>,
    prefix: UnsafePointer<xmlChar>,
    URI: UnsafePointer<xmlChar>,
    nb_namespaces: Int32,
    namespaces: UnsafeMutablePointer<UnsafePointer<xmlChar>>,
    nb_attributes: Int32,
    nb_defaulted: Int32,
    attributes: UnsafeMutablePointer<UnsafePointer<xmlChar>>)
{
    let parser = UnsafeMutablePointer<LibXMLPushSAXParser>(ctx).memory
    
    guard let elementLocalName = getString(localname) else {
        parser.errorOccurred("No local name for element")
        return
    }
    
    let elementPrefix = getString(prefix)
    let elementURI = getString(URI)
    
    let attributesBuffer = LibXMLRawAttribute.getBufferPointerWithStart(attributes, length: Int(nb_attributes))
    var elementAttributes = Dictionary<String, LibXMLAttribute>()
    attributesBuffer.forEach {
        elementAttributes[$0.key] = LibXMLAttribute(rawValue: $0)
    }
   
    parser.startElementWithPrefix(elementPrefix,
        URI: elementURI,
        localName: elementLocalName,
        attributes: elementAttributes)
}

private func XMLPushSAXParserEndElementSAX(ctx: UnsafeMutablePointer<Void>, localname: UnsafePointer<xmlChar>, prefix: UnsafePointer<xmlChar>, URI: UnsafePointer<xmlChar>) {
    let parser = UnsafeMutablePointer<LibXMLPushSAXParser>(ctx).memory
    parser.endElementWithPrefix(getString(prefix),
        URI: getString(URI),
        localName: getString(localname) ?? "")
}

private func XMLPushSAXParserCharactersFoundSAX(ctx: UnsafeMutablePointer<Void>, ch: UnsafePointer<xmlChar>, len: Int32)
{
    let parser = UnsafeMutablePointer<LibXMLPushSAXParser>(ctx).memory
    parser.charactersFound(UnsafePointer<Int8>(ch), length: Int(len))
}

// Swift global variables are guaranteed to be lazy initialized in a thread-safe manner!
internal var XMLPushSAXParserHandlerStruct = { () -> xmlSAXHandler in
    var handler = xmlSAXHandler()
    handler.characters = XMLPushSAXParserCharactersFoundSAX
    handler.initialized = XML_SAX2_MAGIC
    handler.startElementNs = XMLPushSAXParserStartElementSAX
    handler.endElementNs = XMLPushSAXParserEndElementSAX
    handler.error = XMLPushSAXParserErrorEncounteredSAX
    return handler
    }()

private func getString(pointer: UnsafePointer<xmlChar>) -> String? {
    let charPointer = UnsafePointer<CChar>(pointer)
    return String.fromCString(charPointer)
}
