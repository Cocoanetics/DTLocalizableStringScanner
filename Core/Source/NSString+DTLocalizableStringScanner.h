//
//  NSString+DTStringFileParser.h
//  genstrings2
//
//  Created by Oliver Drobnik on 01.01.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Helper methods for string parsing
 */
@interface NSString (DTStringFileParser)

/**
 @name Modifying Strings
 */

/**
 Adds format placeholder numbering to the receiver
 @returns A new string with placeholders numbered
 */
- (NSString *)stringByNumberingFormatPlaceholders;

/**
 Determine predicate variations
 @returns An array with all predicate variations
 */
- (NSArray *)variantsFromPredicateVariations;

/**
 Decodes unicode sequences found in the receiver
 @returns The decoded string
 */
- (NSString *)stringByDecodingUnicodeSequences;

/**
 Replaces slash escapes with the original characters
 @returns The receiver with slash-escapes replaced
 */
- (NSString *)stringByReplacingSlashEscapes;

/**
 Escapes control characters with slash escapes
 @returns The receiver's content with control characters slash-escaped
 */
- (NSString *)stringByAddingSlashEscapes;
@end
