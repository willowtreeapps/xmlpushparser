//
//  XMLBuilder.swift
//  Pods
//
//  Created by Robert Thompson on 11/19/15.
//
//

import Foundation

/// Class representing an XMLDocument. Powered by libxml2 under the hood.
public final class XMLDocument: XMLNode {
    private var docPtr: xmlDocPtr {
        return xmlDocPtr(nodePtr)
    }

    /**
     Designated initializer for XMLDocument

     - returns: initialized XMLDocument with no nodes
     */
    public required init() {
        super.init(nodePtr: xmlNodePtr(xmlNewDoc("1.0")))
    }

    public enum Error: ErrorType {
        case InvalidTypeInDictionary
    }

    /**
     Create a new `XMLNode` that is part of this document. This is the only public way of generating
     `XMLNode`s, because the memory situation gets complicated because `xmlFreeDoc` will free all
     nodes that are in the doc ​*and*​ in the tree, but it won’t free any that are
     a.) in the doc but not in the tree, or b.) in the tree but not in the doc

     - parameter name:    The name of the new node
     - parameter content: The text content of the new node

     - returns: A new `XMLNode` that is not yet part of any tree
     */
    public func newNodeNamed(name: String, content: String = "") -> XMLNode {
        let node = XMLNode(name: name, content: content, document: docPtr)

        return node
    }

    /// Root node of this document. If one does not exist, it will be created with an empty name.
    /// You should give it a name.
    public var rootNode: XMLNode {
        get {
            let root = xmlDocGetRootElement(docPtr)
            if root == nil {
                let node = self.newNodeNamed("", content: "")
                xmlDocSetRootElement(docPtr, node.nodePtr)
                _descendantNodes.insert(node)
                return node
            }

            return XMLNode._objectNodeForNode(root)
        }

        set {
            let oldRoot = xmlDocGetRootElement(docPtr)
            if newValue.nodePtr != oldRoot && oldRoot != nil {
                let oldRootObj = XMLNode._objectNodeForNode(oldRoot)
                if let index = _descendantNodes.indexOf(oldRootObj) {
                    _descendantNodes.removeAtIndex(index)
                }
                xmlUnlinkNode(oldRoot)
            }
            xmlDocSetRootElement(docPtr, newValue.nodePtr)
            _descendantNodes.insert(newValue)
        }
    }

    public override var description: String {
        var output: UnsafeMutablePointer<xmlChar> = nil
        var length: Int32 = 0

        xmlDocDumpMemoryEnc(docPtr, &output, &length, "UTF-8")
        defer { xmlFree(output) }

        return String.fromXMLString(output)
    }
    
    internal override init(nodePtr: xmlNodePtr) {
        super.init(nodePtr: nodePtr)
    }
    
    internal override class func _objectNodeForNode(node: xmlNodePtr) -> XMLDocument {
        precondition(node.memory.type == XML_DOCUMENT_NODE)
        
        if node.memory._private != nil {
            let unmanaged = Unmanaged<XMLDocument>.fromOpaque(COpaquePointer(node.memory._private))
            return unmanaged.takeUnretainedValue()
        }
        
        return XMLDocument(nodePtr: node)
    }
}

extension XMLDocument: DictionaryLiteralConvertible {
    public convenience init(dictionary: [String : AnyObject]) throws {
        self.init()

        let elements = Array(dictionary)
        try self.addChild(parseElements(elements, node: self))
    }

    private func parseElements(elements: [(String, AnyObject)], node: XMLNode) throws -> XMLNode {
        for (key, value) in elements {
            if let string = value as? String {
                node.addChild(self.newNodeNamed(key, content: string))
            } else if let dict = value as? [String : AnyObject] {
                let newNode = self.newNodeNamed(key)
                try node.addChild(parseElements(Array(dict), node: newNode))
            } else {
                throw Error.InvalidTypeInDictionary
            }
        }

        return node
    }

    public convenience init(dictionaryLiteral elements: (String, AnyObject)...) {
        self.init()

        do {
            try self.addChild(parseElements(elements, node: self))
        } catch {
            fatalError("Dictionary must contain only Strings or other Dictionary<String, AnyObject>")
        }
    }
}

public protocol XMLConvertible {
    var xml: XMLDocument { get }
}

public extension XMLConvertible {
    private func xmlNode(doc: XMLDocument) -> XMLNode {
        let mirror = Mirror(reflecting: self)
        
        let node = doc.newNodeNamed("\(mirror.subjectType)".lowercaseString)
        for child in mirror.children {
            let value: XMLNode?
            
            let label = child.label ?? ""

            if let childValue = child.value as? XMLConvertible {
                value = childValue.xmlNode(doc)
            } else if let childValue = child.value as? CustomStringConvertible {
                value = doc.newNodeNamed(label, content: childValue.description)
            } else if let childValue = child.value as? String {
                value = doc.newNodeNamed(label, content: childValue)
            } else {
                value = nil
            }
            
            if let newChild = value {
                node.addChild(newChild)
            }
        }
        
        return node
    }
    
    public var xml: XMLDocument {
        let doc = XMLDocument()
        doc.rootNode = self.xmlNode(doc)
        return doc
    }
}
