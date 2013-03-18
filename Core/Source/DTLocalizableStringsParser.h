//
//  DTLocalizableStringsParser.h
//  genstrings2
//
//  Created by Stefan Gugarel on 2/27/13.
//  Copyright (c) 2013 Drobnik KG. All rights reserved.
//


@class DTLocalizableStringsParser;

/**
 Delegate protocol that informs a DTLocalizableStringsParser delegate about parsing events.
 */
@protocol DTLocalizableStringsParserDelegate <NSObject>

@optional
/**
 @name Parsing Events
 */

/**
 Sent to the delegate for each comment block found
 @param parser The strings parser
 @param comment The comment that was found
 */
- (void)parser:(DTLocalizableStringsParser *)parser foundComment:(NSString *)comment;

/**
 Sent to the delegate for each comment block found
 @param parser The strings parser
 @param key The key that was found
 @param value The value that was found
 */
- (void)parser:(DTLocalizableStringsParser *)parser foundKey:(NSString *)key value:(NSString *)value;

/**
 Sent to the delegate once parsing has finished
 @param parser The strings parser
 */
- (void)parserDidStartDocument:(DTLocalizableStringsParser *)parser;

/**
Sent to the delegate once parsing has finished
 @param parser The strings parser
 */
- (void)parserDidEndDocument:(DTLocalizableStringsParser *)parser;

/**
 Sent to the delegate if an error occurs
 @param parser The strings parser
 @param parseError The parsing error
 */
- (void)parser:(DTLocalizableStringsParser *)parser parseErrorOccurred:(NSError *)parseError;

@end

/**
 Parser for strings files. You initialize it with a file URL, set a delegate and execute parsing with parse.
 */
@interface DTLocalizableStringsParser : NSObject

/**
 @name Creating a Parser
 */

/**
 Instantiates a strings file parser
 @param url The file URL for the file to parse
 */
- (id)initWithFileURL:(NSURL *)url;

/**
 @name Parsing File Contents
 */

/**
 Parses the file.
 @returns `YES` if parsing was successful.
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
