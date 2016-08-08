//
//  LibXMLPushSAXParser.h
//
//  Created by Ian Terrell on 7/15/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// This struct corresponds to the memory layout libxml2 puts in the "attributes" pointer
// for an attribute. Implemented here to ensure future compatibility regardless of changes to the
// Swift ABI. I'm also completely baffled as to why libxml2 doesn't define this struct itself.
typedef struct _LibXMLRawAttribute {
    char* localName;
    char* prefix;
    char* URI;
    char* valueStart;
    char* valueEnd;
} LibXMLRawAttribute;

// Swift will only import this as typealias ErrorFunctionPointer = COpaquePointer
typedef void (*LibXMLErrorFunctionPointer)(void *ctx, const char *msg, ...);

// This exposes the function pointer to Swift
extern const LibXMLErrorFunctionPointer XMLPushSAXParserErrorEncounteredSAX;

NS_ASSUME_NONNULL_END