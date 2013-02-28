//
//  DTLocalizableStringsParser.m
//  genstrings2
//
//  Created by Stefan Gugarel on 2/27/13.
//  Copyright (c) 2013 Drobnik KG. All rights reserved.
//

#import "DTLocalizableStringsParser.h"
#import "NSString+DTLocalizableStringScanner.h"

NSString * const DTLocalizableStringsParserErrorDomain = @"DTLocalizableStringsParser";

@implementation DTLocalizableStringsParser
{
    NSURL *_URL;
    NSError *_parseError;
    
    __unsafe_unretained id <DTLocalizableStringsParserDelegate> _delegate;
    
    // lookup bitmask what delegate methods are implemented
	struct
	{
		unsigned int delegateSupportsDocumentStart:1;
		unsigned int delegateSupportsDocumentEnd:1;
		unsigned int delegateSupportsError:1;
		unsigned int delegateSupportsComment:1;
		unsigned int delegateSupportsKeyValue:1;
	} _delegateFlags;
    
    // character array
    unichar *_characters;
    
    NSUInteger _currentIndex;
    
    NSRange _charactersRange;
    
    NSString *_currentKey;
}

- (id)initWithFileURL:(NSURL *)URL
{
    self = [super init];
    if (self)
    {
        _URL = URL;
    }
    return self;
}

- (void)_reportError:(NSError *)error
{
    _parseError = error;
    
    if (_delegateFlags.delegateSupportsError)
    {
        [_delegate parser:self parseErrorOccurred:error];
    }
}

- (void)_reportErrorMessage:(NSString *)message
{
    NSUInteger line;
    NSUInteger column;
    [self _getCurrentLine:&line column:&column];
    
    NSString *msg = [NSString stringWithFormat:@"%@ in file %@ at line: %ld row: %ld",message, [_URL path], (unsigned long)line, (unsigned long)column];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:msg forKey:NSLocalizedDescriptionKey];
    NSError *error = [NSError errorWithDomain:DTLocalizableStringsParserErrorDomain code:1 userInfo:userInfo];
    
    [self _reportError:error];
}



#define IS_WHITESPACE(_c) (_c == ' ' || _c == '\t' || _c == 0xA || _c == 0xB || _c == 0xC || _c == 0xD || _c == 0x85)

- (void)_scanWhitespace
{
    while (IS_WHITESPACE(_characters[_currentIndex]) && _currentIndex < _charactersRange.length)
    {
        _currentIndex++;
    }
}

// returns a string or nil if invalid, in case of error it does not modify the current index
- (NSString *)_scanComment
{
    NSUInteger currentIndex = _currentIndex;
    
    if (_characters[currentIndex++] != '/')
    {
        return nil;
    }
    
    if (currentIndex >= _charactersRange.length-1)
    {
        return nil;
    }
    
    // next character determins if this is a single or multi line comment
    
    unichar character = _characters[currentIndex++];
    
    BOOL isMultiLine = NO;
    
    if (character == '/')
    {
        isMultiLine = NO; // ends at \n
    }
    else if (character == '*')
    {
        isMultiLine = YES; // ends at star slash
    }
    else
    {
        // unexpected character
        return nil;
    }
    
    NSUInteger commentStringStart = currentIndex;
    NSUInteger commentStringEnd = currentIndex;
    
    BOOL didSeeEndOfComment = NO;
    
    while (_currentIndex < _charactersRange.length)
    {
        unichar character = _characters[currentIndex++];
        
        if (isMultiLine)
        {
            if (character == '*')
            {
                // check if this is followed by slash
                if (_currentIndex < _charactersRange.length)
                {
                    character = _characters[currentIndex++];
                    
                    if (character == '/')
                    {
                       // star-slash terminates multi-line comment
                        commentStringEnd = currentIndex-2;
                        didSeeEndOfComment = YES;
                        
                        break;
                    }
                }
                else
                {
                    break;
                }
                
                
                // character is part of multi-line comment
            }
        }
        else
        {
            if (character == '\n')
            {
                    // EOL terminates single-line comment
                    commentStringEnd = currentIndex--;
                    didSeeEndOfComment = YES;
                    
                    break;
            }
            
            // character is part of single-line comment
        }
    }
    
    if (!didSeeEndOfComment)
    {
        return nil;
    }
    
    _currentIndex = currentIndex;
    
    NSUInteger stringLength = currentIndex - commentStringStart;
    
    // we don't use the NoCopy variant, because we need this string to out-live the _characters buffer
    NSString *string = [[NSString alloc] initWithCharacters:(_characters+commentStringStart) length:stringLength];
    
    return string;
    
    return nil;
}

// returns a string or nil if invalid, in case of error it does not modify the current index
- (NSString *)_scanQuotedString
{
    NSUInteger currentIndex = _currentIndex;
    
    if (_characters[currentIndex] != '"')
    {
        return nil;
    }
    
    NSUInteger quotedStringStart = currentIndex;
    
    // move past the opening quote
    currentIndex++;
    
    BOOL isEscaping = NO;
    BOOL didSeeClosingQuote = NO;
    
    while (_currentIndex < _charactersRange.length)
    {
        unichar character = _characters[currentIndex++];
                
        if (character == '"')
        {
            if (isEscaping)
            {
                isEscaping = NO;
            }
            else
            {
                didSeeClosingQuote = YES;
                
                break;
            }
        }
        else if (character == '\n')
        {
            break;
        }
        else if (character == '\\')
        {
            if (isEscaping)
            {
                // escaped backslash
                isEscaping = NO;
            }
            else
            {
                isEscaping = YES;
            }
        }
        else
        {
            // any other character stops escaping
            isEscaping = NO;
        }
    }
    
    if (!didSeeClosingQuote)
    {
        return nil;
    }
    
    _currentIndex = currentIndex;
    
    NSUInteger stringLength = currentIndex - quotedStringStart - 2;
    
    // we don't use the NoCopy variant, because we need this string to out-live the _characters buffer
    NSString *string = [[NSString alloc] initWithCharacters:(_characters+quotedStringStart+1) length:stringLength];
    
    return string;
}

- (BOOL)parse
{
    if (_delegateFlags.delegateSupportsDocumentStart)
    {
        [_delegate parserDidStartDocument:self];
    }

    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfURL:_URL usedEncoding:NULL error:&error];
    
    if (!fileContents)
    {
        [self _reportError:error];
        return NO;
    }
    
    // get characters from the string
    _charactersRange = NSMakeRange(0, [fileContents length]);
    _characters = calloc(_charactersRange.length, sizeof(unichar));
    [fileContents getCharacters:_characters range:_charactersRange];
    
    _currentIndex = 0;

    // ignore whitespace
    [self _scanWhitespace];
    
    while (_currentIndex<_charactersRange.length)
    {        
        unichar ch = _characters[_currentIndex];
        
        if (ch == '/')
        {
            // comment
            NSString *comment = [self _scanComment];
            
            if (comment)
            {
                if (_delegateFlags.delegateSupportsComment)
                {
                    [_delegate parser:self foundComment:comment];
                }
            }
            else
            {                
                [self _reportErrorMessage:@"Invalid Comment"];
                
                return NO;
            }
            
            // ignore whitespace after comment
            [self _scanWhitespace];
            
            // next loop
            continue;
        }
        else if (ch == '\"')
        {
            // key/value pair
            NSString *key = [self _scanQuotedString];
            
            if (key)
            {
                _currentKey = key;
            }
            else
            {
                [self _reportErrorMessage:@"Invalid Key"];
                
                return NO;
            }
        }
        else
        {
            [self _reportErrorMessage:@"Unexptected Character"];
            
            return NO;
        }
        
        // ignore whitespace
        [self _scanWhitespace];
 
        // must be equal sign next
        
        if (_characters[_currentIndex] == '=')
        {
            _currentIndex++;
        }
        else
        {
            [self _reportErrorMessage:@"Missing equal sign"];
            
            return NO;
        }
        
        // ignore whitespace
        [self _scanWhitespace];
        
        NSString *value = [self _scanQuotedString];
        
        if (value)
        {
            if (_delegateFlags.delegateSupportsKeyValue)
            {
                [_delegate parser:self foundKey:[_currentKey stringByReplacingSlashEscapes] value:[value stringByReplacingSlashEscapes]];
            }
            
            _currentKey = nil;
        }
        else
        {
            [self _reportErrorMessage:@"Invalid Value"];
            
            return NO;
        }
        
        // ignore whitespace
        [self _scanWhitespace];
        
        
        // must be semi-colon next
        if (_characters[_currentIndex] == ';')
        {
            _currentIndex++;
        }
        else
        {
            [self _reportErrorMessage:@"Missing semi-colon"];
            
            return NO;
        }
        
        // ignore whitespace
        [self _scanWhitespace];
    }
    
    if (_delegateFlags.delegateSupportsDocumentEnd)
    {
        [_delegate parserDidEndDocument:self];
    }
    
    return YES;
}


- (void)_getCurrentLine:(NSUInteger *)line column:(NSUInteger *)column
{
    
    NSUInteger currentIndex = 0;
    NSUInteger lineCounter = 1;
    NSUInteger columnCounter = 1;
    
    while(currentIndex<_currentIndex)
    {
        columnCounter ++;
        
        if (_characters[currentIndex] == '\n')
        {
            columnCounter = 1;
            lineCounter ++;
        }
        
        currentIndex ++;
    }
    
    if (line)
    {
        *line = lineCounter;
    }
    if (column)
    {
        *column = columnCounter;
    }
}


/*
- (DTLocalizableStringTable *)stringTable
{
    // read everything from text
    NSError *error = nil;
    NSStringEncoding usedEncoding;
    NSString *fileContents =  [NSString stringWithContentsOfURL:_URL usedEncoding:&usedEncoding error:&error];
    
    // get all lines of file
    NSArray *allLinedStrings = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    
    NSString *tableName = [_url lastPathComponent];
    tableName = [tableName stringByDeletingPathExtension];
    
    DTLocalizableStringTable *stringsTable = [[DTLocalizableStringTable alloc] initWithName:tableName];
        
    NSString *comment;
    
    for (NSString *singleLine in allLinedStrings)
    {
        if (!singleLine.length)
        {
            // skip on empty line
            continue;
        }
        
        NSRange commentOccurence = [singleLine rangeOfString:@""];
        NSRange localizedStringOccurence = [singleLine rangeOfString:@"\""];
        
        if (commentOccurence.location < localizedStringOccurence.location)
        {
            comment = [self _parseCommentFromLine:singleLine];
        }
        else
        {
            NSString *key = nil;
            NSString *value = nil;
            
            [self _parseKeyAndLocalizedString:singleLine key:&key value:&value];
            
            if (key && value)
            {
                DTLocalizableStringEntry *entry = [[DTLocalizableStringEntry alloc] init];
                entry.rawKey = key;
                entry.rawValue = value;
                entry.tableName = tableName;
                [entry setComment:comment];
                
                
                [stringsTable addEntry:entry];
                
                comment = nil;
            }
        }
    }
    
    return stringsTable;
}


- (NSString *)_parseCommentFromLine:(NSString *)line
{
    NSScanner *scanner = [NSScanner scannerWithString:line];
    
    [scanner scanUpToString:@"" intoString:nil];
    
    if (scanner.isAtEnd)
    {
        return nil;
    }
    
    NSUInteger startIndex = scanner.scanLocation + 2;
    
    [scanner scanUpToString:@"" intoString:nil];
    
    NSUInteger endIndex = scanner.scanLocation;
    
    return [scanner.string substringWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
}


- (void)_parseKeyAndLocalizedString:(NSString *)line key:(NSString **)key value:(NSString **)value
{
    NSScanner *scanner = [NSScanner scannerWithString:line];
    
    NSMutableDictionary *commaOccurences = [NSMutableDictionary dictionary];
    NSMutableArray *equalOccurences = [NSMutableArray array];
    
    // scan for "
    while(!scanner.isAtEnd)
    {
        [scanner scanUpToString:@"\"" intoString:nil];
        if (scanner.isAtEnd)
        {
            break;
        }
        commaOccurences[@(scanner.scanLocation)] = @(scanner.scanLocation);
        scanner.scanLocation ++;
    }
    
    // scan for escaped \"
    scanner.scanLocation = 0;
    while (!scanner.isAtEnd)
    {
        [scanner scanUpToString:@"\\\"" intoString:nil];
        if (scanner.isAtEnd)
        {
            break;
        }
        [commaOccurences removeObjectForKey:@(scanner.scanLocation + 1)];
        scanner.scanLocation ++;
    }
    
    // scan for equal sign =
    scanner.scanLocation = 0;
    while (!scanner.isAtEnd)
    {
        [scanner scanUpToString:@"=" intoString:nil];
        if (scanner.isAtEnd)
        {
            break;
        }
        [equalOccurences addObject:@(scanner.scanLocation)];
        scanner.scanLocation ++;
    }
    
    NSRange lastSemicolon = [line rangeOfString:@";" options:NSBackwardsSearch];
    
    // sort comma array
    NSArray *commaArray = [commaOccurences allKeys];
    commaArray = [commaArray sortedArrayUsingSelector:@selector(compare:)];
    
    // set found index for " of key
    NSUInteger keyStart = [commaArray[0] unsignedIntegerValue];
    NSUInteger keyEnd = [commaArray[1] unsignedIntegerValue];
    
    // set found index for " of value
    NSUInteger valueStart = [commaArray[2] unsignedIntegerValue];
    NSUInteger valueEnd = [commaArray[3] unsignedIntegerValue];
    
    // checks
    if (commaArray.count != 4)
    {
        // count of " is not 4
        return;
    }
    
    if (lastSemicolon.location <= valueEnd)
    {
        // no semicolon found
        return;
    }
    
    BOOL equalSignValid = NO;
    for (NSNumber *equalIndex in equalOccurences)
    {
        if ([equalIndex unsignedIntegerValue] > keyEnd && [equalIndex unsignedIntegerValue] < valueStart)
        {
            equalSignValid = YES;
            break;
        }
    }
    
    if (!equalSignValid)
    {
        // no valid equal sign found between key and value
        return;
    }

    // key and value are found
    *key = [line substringWithRange:NSMakeRange(keyStart, keyEnd - keyStart + 1)];
    *value = [line substringWithRange:NSMakeRange(valueStart, valueEnd - valueStart + 1)];
}
 
 */

#pragma mark - Properties

- (void)setDelegate:(id<DTLocalizableStringsParserDelegate>)delegate
{
    if (_delegate != delegate)
    {
        _delegate = delegate;
    
        _delegateFlags.delegateSupportsDocumentStart = [_delegate respondsToSelector:@selector(parserDidStartDocument)];
        _delegateFlags.delegateSupportsDocumentEnd = [_delegate respondsToSelector:@selector(parserDidEndDocument)];
        _delegateFlags.delegateSupportsError = [_delegate respondsToSelector:@selector(parser:parseErrorOccurred:)];
    
        _delegateFlags.delegateSupportsComment = [_delegate respondsToSelector:@selector(parser:foundComment:)];
        _delegateFlags.delegateSupportsKeyValue = [_delegate respondsToSelector:@selector(parser:foundKey:value:)];
    }
}

@synthesize delegate = _delegate;
@synthesize parseError = _parseError;

@end
