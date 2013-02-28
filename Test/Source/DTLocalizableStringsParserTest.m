//
//  DTLocalizableStringsParserTest.m
//  genstrings2
//
//  Created by Stefan Gugarel on 2/28/13.
//  Copyright (c) 2013 Drobnik KG. All rights reserved.
//

#import "DTLocalizableStringsParserTest.h"
#import "DTLocalizableStringsParser.h"

@interface DTLocalizableStringsParserTest() <DTLocalizableStringsParserDelegate>

@end

@implementation DTLocalizableStringsParserTest


- (void)testKeyValueParsing
{
    NSURL *localizableStringsURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Localizable" withExtension:@"strings"];
    
    DTLocalizableStringsParser *parser = [[DTLocalizableStringsParser alloc] initWithFileURL:localizableStringsURL];
    parser.delegate = self;
    
    STAssertTrue([parser parse], @"Failed to parse: %@", parser.parseError);
}

#pragma mark - DTLocalizableStringsParserDelegate

/*
- (void)parser:(DTLocalizableStringsParser *)parser foundKey:(NSString *)key value:(NSString *)value
{
    NSLog(@"%@ - %@", key, value);
}

- (void)parser:(DTLocalizableStringsParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"%@", [parseError localizedDescription]);
}
 */

@end
