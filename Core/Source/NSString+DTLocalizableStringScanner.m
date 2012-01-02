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


@end
