//
//  XMLDocumentTests.swift
//  Salix
//
//  Created by Robert Thompson on 11/23/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import XCTest
@testable import XMLPushParser

class XMLDocumentTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCreateDocument() {
        let doc = XMLDocument()
        doc.addChild(doc.newNodeNamed("request", content: ""))
        let deviceId = doc.newNodeNamed("deviceId", content: "iradeviceid")
        doc.rootNode.addChild(deviceId)
        let array = doc.newNodeNamed("array")
        doc.rootNode.addChild(array)
        let item1 = doc.newNodeNamed("item", content: "first item")
        let item2 = doc.newNodeNamed("item", content: "second item")
        array.addChild(item1)
        array.addChild(item2)

        XCTAssert(doc.description == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<request><deviceId>iradeviceid</deviceId><array><item>first item</item><item>second item</item></array></request>\n", "doc: \(doc)")
    }

    func testReplaceRootNode() {
        let doc = XMLDocument()
        doc.addChild(doc.newNodeNamed("root1"))
        doc.rootNode.addChild(doc.newNodeNamed("child1"))
        XCTAssert(doc.description == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root1><child1></child1></root1>\n", "Doc: \(doc)")

        let newRoot = doc.newNodeNamed("root2")
        newRoot.addChild(doc.newNodeNamed("child2"))

        doc.rootNode = newRoot

        XCTAssert(doc.description == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root2><child2></child2></root2>\n", "Doc: \(doc)")
    }

    func testDefaultRootNode() {
        let doc = XMLDocument()
        doc.rootNode.name = "rootNode"
        doc.rootNode.addChild(doc.newNodeNamed("childNode"))

        XCTAssert(doc.description == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<rootNode><childNode></childNode></rootNode>\n", "Doc: \(doc)")
    }

    func testDictionaryInit() {
        let dict = ["request" : ["deviceId" : "835C167A-D301-4927-B87F-C09E74963940", "deviceToken": "Blahblahblahlk3;waierjljasd;kje", "deviceName": "iPhone Simulator", "deviceType": "iPhone"]]
        do {
            let doc = try XMLDocument(dictionary: dict)

            let expectedResult = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<request><deviceToken>Blahblahblahlk3;waierjljasd;kje</deviceToken><deviceName>iPhone Simulator</deviceName><deviceId>835C167A-D301-4927-B87F-C09E74963940</deviceId><deviceType>iPhone</deviceType></request>\n"
            XCTAssert(doc.description == expectedResult, doc.description)
        } catch {
            XCTFail("\(error)")
        }

        do {
            let _ = try XMLDocument(dictionary: ["BadDict" : 23])
        } catch {
            guard case XMLDocument.Error.InvalidTypeInDictionary = error else {
                XCTFail("\(error)")
                return
            }
        }
    }

    func testDictionaryLiteralConvertible() {

        func testFunc(doc: XMLDocument) {
            let expectedResult = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<request><deviceToken>Blahblahblahlk3;waierjljasd;kje</deviceToken><deviceName>iPhone Simulator</deviceName><deviceId>835C167A-D301-4927-B87F-C09E74963940</deviceId><deviceType>iPhone</deviceType></request>\n"
            XCTAssert(doc.description == expectedResult, doc.description)
        }

        testFunc(["request" : ["deviceId" : "835C167A-D301-4927-B87F-C09E74963940", "deviceToken": "Blahblahblahlk3;waierjljasd;kje", "deviceName": "iPhone Simulator", "deviceType": "iPhone"]])
    }
    
    func testObtuse() {
        let doc = xmlNewDoc("1.0")
        let node = xmlNewDocNode(doc, nil, "root", nil)
        
        let foo = xmlNewDocNode(doc, nil, "foo", nil)
        let bar = xmlNewDocNode(doc, nil, "bar", nil)
        
        xmlAddChild(node, foo)
        xmlAddChild(foo, bar)
        
        let xmlNode = XMLNode(nodePtr: node)
        
        xmlDocSetRootElement(doc, node)
        
        let xmlDoc = xmlNode.parent!
        XCTAssertEqual(xmlDocPtr(xmlDoc.nodePtr), doc)
        let barNode = XMLNode(nodePtr: bar)
        XCTAssertEqual(barNode.parent, XMLNode._objectNodeForNode(foo))
    }
}
