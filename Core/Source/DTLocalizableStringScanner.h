//
//  DTStringFileParser.h
//  genstrings2
//
//  Created by Oliver Drobnik on 29.12.11.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTLocalizableStringScanner;

@protocol DTLocalizableStringScannerDelegate <NSObject>
@optional

- (void)localizableStringScannerDidStartDocument:(DTLocalizableStringScanner *)scanner;
- (void)localizableStringScannerDidEndDocument:(DTLocalizableStringScanner *)scanner;
- (void)localizableStringScanner:(DTLocalizableStringScanner *)scanner didFindToken:(NSDictionary *)token;

@end


@interface DTLocalizableStringScanner : NSObject

- (id)initWithContentsOfURL:(NSURL *)url;

- (BOOL)scanFile;

- (void)registerDefaultMacros;
- (void)registerMacrosWithPrefix:(NSString *)macroPrefix;
- (void)registerMacroWithPrototypeString:(NSString *)prototypeString;

@property (nonatomic, weak) id <DTLocalizableStringScannerDelegate> delegate;

@end



