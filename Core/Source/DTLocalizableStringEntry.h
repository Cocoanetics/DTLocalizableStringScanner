//
//  DTLocalizableStringEntry.h
//  genstrings2
//
//  Created by Oliver Drobnik on 10.01.12.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTLocalizableStringEntry;

@interface DTLocalizableStringEntry : NSObject

@property (nonatomic, copy) NSString *rawKey;
@property (nonatomic, copy) NSString *rawValue;
@property (nonatomic, copy) NSString *tableName;
@property (nonatomic, copy) NSString *bundle;

@property (nonatomic, readonly) NSString *cleanedKey;
@property (nonatomic, readonly) NSString *cleanedValue;

- (void)setComment:(NSString *)comment; // for KVC

- (void)addComment:(NSString *)comment;
- (NSArray *)sortedComments;

// used for output sorting
- (NSComparisonResult)compare:(DTLocalizableStringEntry *)otherEntry;

@end
