//
//  DTStringFileParser.h
//  genstrings2
//
//  Created by Oliver Drobnik on 29.12.11.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTLocalizableStringScanner : NSObject


- (id)initWithContentsOfURL:(NSURL *)url;

- (BOOL)parse;
- (NSArray *)scanResults;

- (void)registerMacroWithPrototypeString:(NSString *)prototypeString;

@end
