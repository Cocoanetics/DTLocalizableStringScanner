//
//  DTLocalizableStringsParser.h
//  genstrings2
//
//  Created by Stefan Gugarel on 2/27/13.
//  Copyright (c) 2013 Drobnik KG. All rights reserved.
//


@class DTLocalizableStringsParser;

@protocol DTLocalizableStringsParserDelegate <NSObject>

@optional

/**
 Sent to the delegate for each comment block found
 */
- (void)parser:(DTLocalizableStringsParser *)parser foundComment:(NSString *)comment;

/**
 Sent to the delegate for each comment block found
 */
- (void)parser:(DTLocalizableStringsParser *)parser foundKey:(NSString *)key value:(NSString *)value;

/**
 Sent to the delegate once parsing has finished
 */
- (void)parserDidStartDocument:(DTLocalizableStringsParser *)parser;

/**
Sent to the delegate once parsing has finished
 */
- (void)parserDidEndDocument:(DTLocalizableStringsParser *)parser;

/**
 Sent to the delegate if an error occurs
 */
- (void)parser:(DTLocalizableStringsParser *)parser parseErrorOccurred:(NSError *)parseError;

@end

/**
 Parser for strings files. You initialize it with a file URL, set a delegate and start parsing with parse. This returns `YES` in case of success.
 */
@interface DTLocalizableStringsParser : NSObject

/**
 @name Creating a Parser
 */

/**
 Instantiates a strings file parser
 */
- (id)initWithFileURL:(NSURL *)url;

/**
 @name Parsing File Contents
 */

/**
 Parses the file.
 */
- (BOOL)parse;

/**
 The parser delegate
 */
@property (nonatomic, unsafe_unretained) id <DTLocalizableStringsParserDelegate> delegate;

/**
 The last reported parse error
 */
@property (nonatomic, readonly) NSError *parseError;

@end
