//
//  DTStringFileParser.h
//  genstrings2
//
//  Created by Oliver Drobnik on 29.12.11.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTLocalizableStringEntry;

typedef void(^DTLocalizableStringEntryFoundCallback)(DTLocalizableStringEntry *);

/**
 Source Code scanner operation, based on `NSOperation`. Scans a a source file and emits an entryFoundCallback whenever a new localized string Macro is encountered.
 */

@interface DTLocalizableStringScanner : NSOperation

/**
 @name Creating a Scanner
 */

/**
 Creates a source scanner operation.
 @param url The file URL of the file to scan
 @param encoding The string encoding of the source file
 @param validMacros The macro prototypes that are considered valid
 */
- (id)initWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding)encoding validMacros:(NSDictionary *)validMacros;

/**
 The callback to execute for each found macro.
 */
@property (nonatomic, copy) DTLocalizableStringEntryFoundCallback entryFoundCallback;

@end



