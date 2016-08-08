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
            XCTAssertEqual("<Node\(i)><grandchild>hello world</grandchild></Node\(i)>", child.description)
            i += 1
        }
        
        let nodes = node.dropLast()
        XCTAssertEqual(9, nodes.count)
        let lastIndex = nodes.index(nodes.startIndex, offsetBy: nodes.count-1)
        XCTAssertEqual("<Node8><grandchild>hello world</grandchild></Node8>", nodes[lastIndex].description)
        XCTAssertEqual(node.first, nodes.first)
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
        
        XCTAssertEqual([newNode], childNode)
    }
    
    func testRemoveChild() {
        let node = doc.newNodeNamed("root")
        
        for i in 0..<10 {
            node.addChild(doc.newNodeNamed("child", content: "\(i)"))
        }
        
        XCTAssert(node.count == 10)
        
        var index = node.startIndex
        index = node.index(after: index)
        index = node.index(after: index)
        let nodeToRemove = node[index]
        XCTAssert(nodeToRemove.content == "2", nodeToRemove.content)
        node.removeChild(nodeToRemove)
        
        XCTAssert(node.count == 9)
        
        var newIndex = node.startIndex
        newIndex = node.index(after: newIndex)
        newIndex = node.index(after: newIndex)
        let newNode = node[newIndex]
        XCTAssert(newNode.content == "3", newNode.content)
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
