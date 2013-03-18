//
//  DTLocalizableStringEntry.h
//  genstrings2
//
//  Created by Oliver Drobnik on 10.01.12.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTLocalizableStringEntry;

/**
 An entry in a string table
 */

@interface DTLocalizableStringEntry : NSObject

/**
 @name Getting Information about Entries
 */

/**
 The raw key as it was found in the original file
 */
@property (nonatomic, copy) NSString *rawKey;

/**
 The raw value as it was found in the original file
 */
@property (nonatomic, copy) NSString *rawValue;

/**
 The name of the table that this entry belongs to
 */
@property (nonatomic, copy) NSString *tableName;

/**
 The bundle name that this entry belongs to
 */
@property (nonatomic, copy) NSString *bundle;

/**
 The contents of the rawKey with escape sequences removed
 */
@property (nonatomic, readonly) NSString *cleanedKey;

/**
 The contents of the rawValue with escape sequences removed
 */
@property (nonatomic, readonly) NSString *cleanedValue;

/**
 @name Working with Comments
 */

/**
 Removes all existing comments and sets a single one.
 @param comment The comment to set.
 */
- (void)setComment:(NSString *)comment;

/**
 Appends the comment to the receiver's list of comments
  @param comment The comment to add.
 */
- (void)addComment:(NSString *)comment;

/**
 An alphabetically sorted list of comments. This property is cached internally.
 @returns The sorted comments
 */
- (NSArray *)sortedComments;

/**
 @name Sorting Entries
 */

/**
 Compares the receiver against another entry. This is used for output sorting.
 @param otherEntry The other entry to compare against
 @return An `NSComparisonResult`
 */
- (NSComparisonResult)compare:(DTLocalizableStringEntry *)otherEntry;

@end
