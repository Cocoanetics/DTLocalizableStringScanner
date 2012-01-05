//
//  NSString+DTStringFileParser.m
//  genstrings2
//
//  Created by Oliver Drobnik on 01.01.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import "NSString+DTLocalizableStringScanner.h"

@implementation NSString (DTStringFileParser)

- (NSString *)stringByNumberingFormatPlaceholders
{
    NSMutableString *tmpString = [NSMutableString string];
    
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.charactersToBeSkipped = nil;
    
    NSUInteger placeholderCount = 0;
    
    while (![scanner isAtEnd])
    {
        // scan until percent
        NSString *part = nil;
        if ([scanner scanUpToString:@"%" intoString:&part])
        {
            [tmpString appendString:part];
        }
        
        if ([scanner scanString:@"%" intoString:NULL])
        {
            // scan for escaped percent
            if ([scanner scanString:@"%" intoString:NULL])
            {
                [tmpString appendString:@"%%"];
            }
            else
            {
                // just insert the number
                placeholderCount++;
                [tmpString appendFormat:@"%%%d$", placeholderCount];
            }
        }
    }
    
    // only number if there is more than one placeholder
    if (placeholderCount>1)
    {
        return tmpString;
    }
    else
    {
        return self;
    }
}

- (NSArray *)variantsFromPredicateVariations
{
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.charactersToBeSkipped = nil; // we need whitespace too
    
    NSMutableArray *stringParts = [NSMutableArray array];
    
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    // build an array of string parts: NSString, NSArray, NSString ...
    while (![scanner isAtEnd]) 
    {
        NSString *part = nil;
        
        // skip to first [
        if ([scanner scanUpToString:@"%[" intoString:&part])
        {
            [stringParts addObject:part];
        }
        
        // do we have a list?
        if ([scanner scanString:@"%[" intoString:NULL])
        {
            NSString *tokenList = nil;
            
            [stringParts addObject:@"%["];
            
            if ([scanner scanUpToString:@"]" intoString:&tokenList])
            {
                // do we have a closing?
                if ([scanner scanString:@"]" intoString:NULL])
                {
                    // dissove list
                    NSArray *listElements = [tokenList componentsSeparatedByString:@","];
                    NSMutableArray *tmpList = [NSMutableArray array];
                    
                    for (NSString *oneElement in listElements)
                    {
                        [tmpList addObject:[oneElement stringByTrimmingCharactersInSet:whitespaceSet]];
                    }
                    
                    [stringParts addObject:tmpList];
                    
                    [stringParts addObject:@"]"];
                }
            }
        }
    }
    
    NSMutableArray *results = [NSMutableArray array];
    
    // generate all variants
    for (id part in stringParts)
    {
        @autoreleasepool 
        {
            if ([part isKindOfClass:[NSArray class]])
            {
                // this is an array
                NSMutableArray *newResults = [NSMutableArray array];
                
                // copy all previous results and append all elements from array
                if ([results count])
                {
                    for (NSString *oneToken in part)
                    {
                        for (NSString *oneResult in results)
                        {
                            NSMutableString *copiedResult = [oneResult mutableCopy];
                            [copiedResult appendString:oneToken];
                            
                            [newResults addObject:copiedResult];
                        }
                    }
                    
                    // new results replace old ones
                    results = newResults;
                }
                else
                {
                    // there was nothing previous, these tokens become the first results
                    for (NSString *oneToken in part)
                    {
                        [results addObject:[oneToken mutableCopy]];
                    }
                }
            }
            else
            {
                // must be an NSString, append to all previous results
                if ([results count])
                {
                    for (NSMutableString *oneResult in results)
                    {
                        [oneResult appendString:part];
                    }
                }
                else
                {
                    // no results yet, this becomes the first result
                    [results addObject:[part mutableCopy]];
                }
            }
        }
    }
    
    
    // only return array if it has entries
    if ([results count])
    {
        return results;
    }
    else
    {
        return nil;
    }
}


@end
