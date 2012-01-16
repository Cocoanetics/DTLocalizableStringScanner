//
//  NSString+DTStringFileParser.h
//  genstrings2
//
//  Created by Oliver Drobnik on 01.01.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DTStringFileParser)

- (NSString *)stringByNumberingFormatPlaceholders;

- (NSArray *)variantsFromPredicateVariations;

- (NSString *)stringByDecodingUnicodeSequences;

- (NSString *)stringByReplacingSlashEscapes;
- (NSString *)stringByAddingSlashEscapes;
@end
