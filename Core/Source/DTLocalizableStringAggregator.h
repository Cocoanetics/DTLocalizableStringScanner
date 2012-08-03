//
//  DTLocalizableStringAggregator.h
//  genstrings2
//
//  Created by Oliver Drobnik on 02.01.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTLocalizableStringEntry.h"

@interface DTLocalizableStringAggregator : NSObject

@property (nonatomic, assign) BOOL wantsPositionalParameters;
@property (nonatomic, assign) NSStringEncoding inputEncoding;
@property (nonatomic, retain) NSSet *tablesToSkip;
@property (nonatomic, retain) NSString *customMacroPrefix;
@property (nonatomic, retain) NSString *defaultTableName;

- (void)beginProcessingFile:(NSURL *)fileURL;

// returns an array of DTLocalizableStringTables
// blocks until all enqueued files have been processed
- (NSArray *)aggregatedStringTables; 

@end
