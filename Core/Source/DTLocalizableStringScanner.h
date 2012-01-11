//
//  DTStringFileParser.h
//  genstrings2
//
//  Created by Oliver Drobnik on 29.12.11.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTLocalizableStringEntry;

typedef void(^DTLocalizableStringEntryFoundCallback)(DTLocalizableStringEntry *);

@interface DTLocalizableStringScanner : NSOperation

- (id)initWithContentsOfURL:(NSURL *)url validMacros:(NSDictionary *)validMacros;

@property (nonatomic, copy) DTLocalizableStringEntryFoundCallback entryFoundCallback;

@end



