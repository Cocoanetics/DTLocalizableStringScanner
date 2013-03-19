//
//  DTLocalizableStringTable.h
//  genstrings2
//
//  Created by Oliver Drobnik on 1/12/12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTLocalizableStringEntry;

typedef void(^DTLocalizableStringEntryWriteCallback)(DTLocalizableStringEntry *);


/**
 Class representing a strings table. A strings table consists of key value pairs which are represented by DTLocalizableStringEntry instances.
 */

@interface DTLocalizableStringTable : NSObject

/**
 @name Getting Information
 */

/**
 Name of the String Table
 */
@property (nonatomic, readonly) NSString *name;

/**
 Whether the receiver should decode unicode sequences
 */
@property (nonatomic, assign) BOOL shouldDecodeUnicodeSequences;

/**
 The string table entries of the receiver
 */
@property (nonatomic, readonly) NSArray *entries;

/**
 @name Creating a String Table
 */

/**
 Creates a new string table with a given name
 @param name The name of the string table
 */
- (id)initWithName:(NSString *)name;

/**
 @name Modifying the String Table
 */

/**
 Appends a new string table entry to the receiver
 @param entry The new entry to add
 */
- (void)addEntry:(DTLocalizableStringEntry *)entry;


/**
 @name Creating Output
 */

/**
 Creates a textual representation of the string table
 @param encoding The output string encoding
 @param error If an error occurs it will be output via this parameter
 @param entryWriteCallback The block to execute before an entry is output
 @returns An `NSString ` containing the contents of the receiver
 */
- (NSString *)stringRepresentationWithEncoding:(NSStringEncoding)encoding error:(NSError **)error entryWriteCallback:(DTLocalizableStringEntryWriteCallback)entryWriteCallback;

/**
 Writes a textual representation of the string table into a file
 @param url The file URL to write to
 @param encoding The output string encoding
 @param error If an error occurs it will be output via this parameter
 @param entryWriteCallback The block to execute before an entry is output
 @returns An `NSString ` containing the contents of the receiver
 */
- (BOOL)writeToFolderAtURL:(NSURL *)url encoding:(NSStringEncoding)encoding error:(NSError **)error entryWriteCallback:(DTLocalizableStringEntryWriteCallback)entryWriteCallback;

@end
