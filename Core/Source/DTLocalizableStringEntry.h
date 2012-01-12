//
//  DTLocalizableStringEntry.h
//  genstrings2
//
//  Created by Oliver Drobnik on 10.01.12.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTLocalizableStringEntry;

typedef void(^DTLocalizableStringEntryWriteCallback)(DTLocalizableStringEntry *);

@interface DTLocalizableStringEntry : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) NSString *tableName;
@property (nonatomic, copy) NSString *bundle;

- (void)setComment:(NSString *)comment; // for KVC

- (void)addComment:(NSString *)comment;
- (NSArray *)sortedComments;

@end
