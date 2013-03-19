//
//  DTLocalizableStringAggregator.h
//  genstrings2
//
//  Created by Oliver Drobnik on 02.01.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTLocalizableStringEntry.h"

/**
 An aggregator that parses one or more source files and aggregates the results in multiple string tables.
 
 You use this be calling beginProcessingFile: for each file. This starts the parsing thread for each file. Then you call aggregatedStringTables which blocks until all files are fully parsed.
 */

@interface DTLocalizableStringAggregator : NSObject

/**
 @name Getting Information about the Aggregator
 */

/**
 If set to `YES` then placeholders are numbered
 */
@property (nonatomic, assign) BOOL wantsPositionalParameters;

/**
 The encoding to use for interpreting the input files
 */
@property (nonatomic, assign) NSStringEncoding inputEncoding;

/**
 The names of the string tables to ignore.
 */
@property (nonatomic, retain) NSSet *tablesToSkip;

/**
 The custom macro prefix to use instead of NSLocalizedString.
 */
@property (nonatomic, retain) NSString *customMacroPrefix;

/**
 The default table name, if not set it defaults to "Localizable".
 */
@property (nonatomic, retain) NSString *defaultTableName;


/**
 @name Scanning Files
 */

/**
 Begins processing a source code file
 @param fileURL The file URL of the code file to process
 */
- (void)beginProcessingFile:(NSURL *)fileURL;

/**
 Retrieves the string tables resulting from the parsing process
 @note blocks until all enqueued files have been processed
 @return An array of DTLocalizableStringTables
 */
- (NSArray *)aggregatedStringTables;

@end
