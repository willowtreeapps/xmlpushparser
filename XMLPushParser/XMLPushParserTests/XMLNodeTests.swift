//
//  XMLNodeTests.swift
//  Salix
//
//  Created by Robert Thompson on 11/24/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import XCTest
@testable import XMLPushParser

class XMLNodeTests: XCTestCase {
    
    private var doc: XMLDocument!
    
    override func setUp() {
        super.setUp()
        
        doc = XMLDocument()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCollectionType() {

        let node = doc.newNodeNamed("topNode")
        for i in 0..<10 {
            let child = doc.newNodeNamed("Node\(i)")
            child.addChild(doc.newNodeNamed("grandchild", content: "hello world"))
            node.addChild(child)
        }
        
        XCTAssert(node.count == 10)
        
        var i = 0
        for child in node {
            if child.description != "<Node\(i)><grandchild>hello world</grandchild></Node\(i)>" {
                XCTFail(child.description)
                break
            }
            i += 1
        }
        
        let nodes = node.dropLast()
        XCTAssert(nodes.count == 9)
        XCTAssert(nodes.last?.description == "<Node8><grandchild>hello world</grandchild></Node8>")
        XCTAssert(nodes.first == node.first)
    }
    
    func testContent() {

        let node = doc.newNodeNamed("Node", content: "Hello world")
        XCTAssert(node.description == "<Node>Hello world</Node>")
        XCTAssert(node.content == "Hello world")
        
        node.content = "Goodbye"
        XCTAssert(node.description == "<Node>Goodbye</Node>")
        XCTAssert(node.content == "Goodbye")
    }
    
    func testName() {
        let node = doc.newNodeNamed("WrongNodeName")
        XCTAssert(node.name == "WrongNodeName")
        
        node.name = "RightNodeName"
        XCTAssert(node.name == "RightNodeName")
        
        XCTAssert(node.description == "<RightNodeName></RightNodeName>")
        
        let newNode = doc.newNodeNamed("Hello", content: "world")
        node.addChild(newNode)
        
        let childNode = node["Hello"]
        
        XCTAssert(childNode == [newNode])
    }
    
    func testRemoveChild() {
        let node = doc.newNodeNamed("root")
        
        for i in 0..<10 {
            node.addChild(doc.newNodeNamed("child", content: "\(i)"))
        }
        
        XCTAssert(node.count == 10)
        
        let index = node.startIndex.successor().successor()
        let nodeToRemove = node[index]
        XCTAssert(nodeToRemove.content == "2", nodeToRemove.content)
        node.removeChild(nodeToRemove)
        
        XCTAssert(node.count == 9)
        
        let newIndex = node.startIndex.successor().successor()
        let newNode = node[newIndex]
        XCTAssert(newNode.content == "3", newNode.content)
    }
    
    func testBidirectionalIndexType() {
        let node = doc.newNodeNamed("root")
        for i in 0..<10 {
            node.addChild(doc.newNodeNamed("child", content: "\(i)"))
        }
        
        let index = node.startIndex
        XCTAssert(index.successor().predecessor() == index)
        XCTAssert(index.predecessor().successor() == index)
    }
    
    func testGarbage() {
        let ptr = UnsafeMutablePointer<UInt8>.alloc(5)
        defer { ptr.dealloc(5) }
        
        ptr[0] = 0xF4
        ptr[1] = 0xFF
        ptr[2] = 0xFF
        ptr[3] = 0xFF
        
        let result = String.fromXMLString(ptr)
        XCTAssert(result == "")
    }
    
    func testParent() {
        let node = doc.newNodeNamed("root")
        let fooNode = doc.newNodeNamed("foo")
        let barNode = doc.newNodeNamed("bar")
        node.addChild(fooNode)
        fooNode.addChild(barNode)
        
        doc.rootNode = node
        
        XCTAssertEqual(barNode.parent, fooNode)
        XCTAssertEqual(fooNode.parent, node)
        XCTAssertEqual(node.parent, doc)
        XCTAssertEqual(doc.parent, nil)
    }
}
