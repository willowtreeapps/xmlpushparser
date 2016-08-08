//
//  XMLNode.swift
//  Pods
//
//  Created by Robert Thompson on 11/19/15.
//
//

import Foundation

let endPtr = XMLDocument().nodePtr

/// XMLNode wraps xmlNodePtr and represents an element node in XML, with optional text content.
///
/// - Important: Should not be subclassed outside of this module.
public class XMLNode: CustomStringConvertible {
    internal let nodePtr: xmlNodePtr

    /// Keep track of all descendant node objects so we don't ever double-free an xmlNodePtr.
    ///
    /// - Remarks:
    /// Calling xmlFreeNode on an xmlNodePtr frees not just the node itself, but all child nodes.
    /// Since we are wrapping xmlNodePtr in a Swift object, it is possible for us to have XMLNode
    /// references to two items in an ancestral relationship in the same tree. Deiniting the
    /// ancestor XMLNode before the descdendant XMLNode would cause the latter's xmlNodePtr to be
    /// attempted to be freed a second time (erroneously) when the descendant XMLNode gets deinited.
    ///
    /// To prevent this, we keep a list of descendant node objects and then on deinit unlink their
    /// underlying xmlNodePtrs. Now the descendant XMLNode object for which we have a reference does
    /// not have its underlying xmlNodePtr dealloced by the anscestor; but will now be freed when
    /// its wrapping XMLNode deinits.
    ///
    /// This works in conjunction with storing a pointer to the wrapping node in the xmlNodePtr's
    /// `_private` context variable.
    internal var _descendantNodes: Set<XMLNode> = []

    internal init(nodePtr: xmlNodePtr) {
        precondition(nodePtr.pointee._private == nil, "Only one XMLNode per xmlNodePtr allowed")
        self.nodePtr = nodePtr
        saveToPrivate()
        addToAnscestor()
    }

    /// Saves an unmanaged reference to `self` in the `nodePtr`. This allows us to retrieve the
    /// object version of a node when all we have is the `xmlNodePtr` (such as when getting the
    /// parent or sibling nodes).
    private func saveToPrivate() {
        let unmanaged = Unmanaged<XMLNode>.passUnretained(self)
        self.nodePtr.pointee._private = UnsafeMutablePointer<Void>(unmanaged.toOpaque())
    }

    /// Adds this node object to the closest anscestor's object's `_descendantNodes` list, if
    /// one exists.
    private func addToAnscestor() {
        var parent = self.nodePtr.pointee.parent
        var foundAncestorObject = false
        while parent != nil {
            if parent!.pointee._private != nil {
                foundAncestorObject = true
                break
            }

            parent = parent!.pointee.parent
        }

        if foundAncestorObject {
            let parentNode = XMLNode._objectNodeForNode(parent!)
            parentNode._descendantNodes.insert(self)
        }
    }

    internal class func _objectNodeForNode(_ node: xmlNodePtr) -> XMLNode {
        switch node.pointee.type {

        case XML_DOCUMENT_NODE:
            return XMLDocument._objectNodeForNode(node)

        default:
            if node.pointee._private != nil {
                let unmanaged = Unmanaged<XMLNode>.fromOpaque(node.pointee._private)
                return unmanaged.takeUnretainedValue()
            }

            return XMLNode(nodePtr: node)
        }
    }

    internal init(name: String, content: String = "", document: xmlDocPtr) {
        nodePtr = xmlNewDocRawNode(document, nil, name, content)
        saveToPrivate()
    }

    /// Name of the node. If this node has no name, returns an empty string.
    public var name: String {
        get {
            if let nodeName = nodePtr.pointee.name {
                return String.fromXMLString(nodeName)
            }
            return ""
        }
        set {
            xmlNodeSetName(nodePtr, newValue)
        }
    }

    /// Text content of the node. If this node has no content, returns an empty string.
    public var content: String {
        get {
            let nodeContent = xmlNodeGetContent(nodePtr)
            defer { xmlFree(nodeContent) }
            return String.fromXMLString(xmlNodeGetContent(nodePtr))
        }
        set {
            xmlNodeSetContent(nodePtr, newValue)
        }
    }

    public var description: String {
        let output = xmlAllocOutputBuffer(nil)
        defer { xmlFree(output) }
        xmlNodeDumpOutput(output, nil, nodePtr, 0, 1, nil)
        return String.fromXMLString(xmlOutputBufferGetContent(output))
    }

    public var parent: XMLNode? {
        guard nodePtr.pointee.parent != nil else {
            return nil
        }

        let parent = XMLNode._objectNodeForNode(nodePtr.pointee.parent)
        if !parent._descendantNodes.contains(self) {
            // this means we had to create the parent node object
            parent._descendantNodes.insert(self)
        }
        return parent
    }

    deinit {
        for node in _descendantNodes {
            xmlUnlinkNode(node.nodePtr)
        }

        _descendantNodes.removeAll()

        // Nodes that are documents have to be free'd using `xmlFreeDoc` or they will leak details
        // that are unique to documents.
        if nodePtr.pointee.type == XML_DOCUMENT_NODE {
            xmlFreeDoc(xmlDocPtr(nodePtr))
        } else {
            xmlFreeNode(nodePtr)
        }
    }
}


// MARK: Equatable

extension XMLNode: Equatable {}

public func ==(left: XMLNode, right: XMLNode) -> Bool {
    return left.hashValue == right.hashValue
}


// MARK: Hashable

extension XMLNode: Hashable {
    public var hashValue: Int {
        return nodePtr.hashValue
    }
}


// MARK: CollectionType


extension XMLNode: Collection {
    public typealias Index = xmlNodePtr

    public subscript(index: Index) -> XMLNode {
        return XMLNode._objectNodeForNode(index)
    }

    public var startIndex: Index {
        return xmlFirstElementChild(nodePtr)
    }

    public var lastIndex: Index {
        return xmlLastElementChild(nodePtr)
    }
    
    public var endIndex: Index {
        return endPtr
    }

    public func index(after ptr: Index) -> Index {
        guard let index = xmlNextElementSibling(ptr) else {
            return endIndex
        }
        return index
    }

    public subscript(nodeName: String) -> [XMLNode] {
        get {
            return self.filter { $0.name == nodeName }
        }
    }

    /// Add a child node to this node.
    ///
    /// - Precondition: Child must not already have a parent.
    public func addChild(_ child: XMLNode) {
        precondition(child.parent == nil, "Cannot add a child that has a parent; detach first")

        xmlAddChild(nodePtr, child.nodePtr)
        _descendantNodes.insert(child)
    }

    public func removeChild(_ child: XMLNode) {
        xmlUnlinkNode(child.nodePtr)
        _descendantNodes.remove(child)
    }

    public var count: Int {
        return Int(xmlChildElementCount(nodePtr))
    }
}

// MARK: Extensions

internal extension String {
    internal static func fromXMLString(_ xmlStr: UnsafePointer<xmlChar>) -> String {
        return String(cString: UnsafePointer<CChar>(xmlStr))
    }
}
