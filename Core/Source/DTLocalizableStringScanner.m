//
//  DTLocalizableStringScanner.m
//  genstrings2
//
//  Created by Oliver Drobnik on 29.12.11.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import "DTLocalizableStringScanner.h"
#import "DTLocalizableStringEntry.h"
#import "NSString+DTLocalizableStringScanner.h"

@interface DTLocalizableStringScanner ()

- (BOOL)_processMacroAtRange:(NSRange)range;

@end

@implementation DTLocalizableStringScanner
{
    NSURL *_url;
    NSDictionary *_validMacros;
    NSRegularExpression *_validMacroRegex;
    
    unichar *_characters;
    NSString *_charactersAsString;
    NSUInteger _currentIndex;
    NSRange _charactersRange;
}

@synthesize entryFoundCallback=_entryFoundCallback;


- (void) rebuildPattern:(NSMutableString *) pattern withDictionary:(NSDictionary *) node {
    NSUInteger count = [node count];
    if (count == 0) {
        return;
    } else if (count == 1) {
        for (NSNumber *key in node) {
            unichar c = [key unsignedShortValue];
            if (c == '|') {
                return;
            }
            
            CFStringAppendCharacters((__bridge CFMutableStringRef) pattern, &c, 1);
            
            NSDictionary *dict = [node objectForKey:key];
            if (dict) {
                [self rebuildPattern:pattern withDictionary:dict];
            }
        }
    } else {
        BOOL isFirst = [pattern length] == 0;
        if (!isFirst) {
            [pattern appendString:@"(?:"];
        }
        
        BOOL ender = NO;
        BOOL firstKey = YES;
        
        NSArray *keys = [[node allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for (NSNumber *key in keys) {
            unichar c = [key unsignedShortValue];
            
            if (c == '|') {
                ender = YES;
            } else {
                if (!firstKey) {
                    [pattern appendString:@"|"];
                }
                firstKey = NO;
                
                CFStringAppendCharacters((__bridge CFMutableStringRef) pattern, &c, 1);
                
                NSDictionary *dict = [node objectForKey:key];
                if (dict) {
                    [self rebuildPattern:pattern withDictionary:dict];
                }                                
            }
        }
        
        if (!isFirst) {
            [pattern appendString:@")"];
            if (ender) {
                [pattern appendString:@"?"];
            }
        }
    }
}

- (NSString *) optimizedAlternationPatternStringWithValidMacros:(NSDictionary *) validMacros {
    NSArray *orderedKeys = [[validMacros allKeys] sortedArrayUsingSelector:@selector(compare:)];

    NSMutableDictionary *root = [NSMutableDictionary dictionary];
    NSMutableDictionary *node;
        
    for (NSString *key in orderedKeys) {
        node = root;
        
        NSUInteger keyLength = [key length];
        
        for (NSUInteger i = 0; i <= keyLength; i++) {
            unichar c;
            if (i < keyLength) {
                c = [key characterAtIndex:i];
            } else {
                c = '|';
            }
            
            // find node for this character
            NSMutableDictionary *thisNode = [node objectForKey:[NSNumber numberWithUnsignedShort:c]];
            if (!thisNode) {
                thisNode = [NSMutableDictionary dictionary];
                [node setObject:thisNode forKey:[NSNumber numberWithUnsignedShort:c]];
            }
            
            node = thisNode;
        }
    }
    
    NSMutableString *pattern = [NSMutableString string];
    [self rebuildPattern:pattern withDictionary:root];
    
    return pattern;
}

- (NSRegularExpression *) regularExpressionWithValidMacros:(NSDictionary *)validMacros {
    @synchronized ([self class]) {
        static NSDictionary *lastValidMacrosDictionary = nil;
        static NSRegularExpression *lastRegularExpression = nil;
        
        if (lastValidMacrosDictionary == validMacros) {
            return lastRegularExpression;
        } else {
            // build regex to find macro words
            NSString *innerPatternPart = [self optimizedAlternationPatternStringWithValidMacros:validMacros];
            NSString *pattern = [NSString stringWithFormat:@"\\b(%@)\\b", innerPatternPart];
            
            //NSLog(@"optimized pattern: %@", pattern);
            
            lastValidMacrosDictionary = validMacros;
            lastRegularExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL];
            
            return lastRegularExpression;
        }
    }
}

- (id)initWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding)encoding validMacros:(NSDictionary *)validMacros
{
    self = [super init];
    
    if (self)
    {
        _charactersAsString = [[NSString alloc] initWithContentsOfURL:url encoding:encoding error:NULL];
        
        if (!_charactersAsString)
        {
            return nil;
        }        
        
        _characters = nil;
            
        _url = [url copy]; // to have a reference later
        
        _validMacros = validMacros;
        _validMacroRegex = [self regularExpressionWithValidMacros:validMacros];
    }
    
    return self;
}

- (void)dealloc 
{
    if (_characters) 
    {
        free(_characters);
    }
}

- (void)main
{
    @autoreleasepool 
    {
        [_validMacroRegex enumerateMatchesInString:_charactersAsString 
                                           options:0 range:NSMakeRange(0, [_charactersAsString length]) 
                                        usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) 
         {
             NSRange matchRange = [match range];
             [self _processMacroAtRange:matchRange]; 
         }];
    }
}


#define IS_WHITESPACE(_c) (_c == ' ' || _c == '\t' || _c == 0xA || _c == 0xB || _c == 0xC || _c == 0xD || _c == 0x85)

- (void)_scanWhitespace 
{
    while (IS_WHITESPACE(_characters[_currentIndex]) && _currentIndex < _charactersRange.length) 
    {
        _currentIndex++;
    }
}

- (NSString *)_scanQuotedString 
{
    if (_characters[_currentIndex] != '"') 
    {
        return nil;
    }
    
    NSUInteger quotedStringStart = _currentIndex;
    
    // move past the opening quote
    _currentIndex++;
    
    BOOL isEscaping = NO;
    BOOL keepGoing = YES;
    while (keepGoing && _currentIndex < _charactersRange.length) 
    {
        unichar character = _characters[_currentIndex];
        
        if (isEscaping) 
        {
            // make "\u" become "\U"
            if (character == 'u') 
            {
                _characters[_currentIndex] = 'U';
            }
            isEscaping = NO;
        }
        else 
        {
            if (character == '\\') 
            {
                isEscaping = YES;
            } 
            else if (character == '"') 
            {
                keepGoing = NO;
            }
        }
        _currentIndex++;
    }
    
    NSUInteger stringLength = _currentIndex - quotedStringStart;
    
    // we don't use the NoCopy variant, because we need this string to out-live the _characters buffer
    NSString *string = [[NSString alloc] initWithCharacters:(_characters+quotedStringStart) length:stringLength];
    
    return string;
}

- (NSString *)_scanParameter 
{
    // TODO: handle comments in parameters
    // eg: NSLocalizedString("Something", /* blah */ nil)
    NSUInteger parameterStartIndex = _currentIndex;
    BOOL keepGoing = YES;
    NSString *quotedString = nil;
    
    NSInteger parenCount = 0;
    
    while (keepGoing && _currentIndex < _charactersRange.length) 
    {
        unichar character = _characters[_currentIndex];
        if (character == ',') 
        {
            keepGoing = NO;
        }
        else if (character == '(') 
        {
            _currentIndex++;
            parenCount++;
        }
        else if (character == ')') 
        {
            parenCount--;
            if (parenCount >= 0) 
            {
                _currentIndex++;
            }
            else 
            {
                keepGoing = NO;
            }
        }
        else if (character == '"') 
        {
            quotedString = [self _scanQuotedString];
        }
        else 
        {
            _currentIndex++;
        }
    }
    
    if (quotedString) 
    {
        return quotedString;
    }
    
    NSUInteger length = _currentIndex - parameterStartIndex;
    return [[NSString alloc] initWithCharacters:(_characters+parameterStartIndex) length:length];
}

- (BOOL)_processMacroAtRange:(NSRange)range
{        
    if (_characters == nil) {
        _charactersRange = NSMakeRange(range.location, [_charactersAsString length] - range.location);        
        _characters = calloc(_charactersRange.length, sizeof(unichar));
        [_charactersAsString getCharacters:_characters range:_charactersRange];
    }     
    _currentIndex = range.location + range.length - _charactersRange.location;
    
    NSMutableArray *parameters = [[NSMutableArray alloc] initWithCapacity:3];
    
    // skip any whitespace between here and the (
    [self _scanWhitespace];
    
    if (_characters[_currentIndex] == '(') 
    {
        // read the opening parenthesis
        _currentIndex++;
        
        while (_currentIndex < _charactersRange.length) 
        {
            // skip any leading whitespace
            [self _scanWhitespace];
            
            // scan a parameter
            NSString *parameter = [self _scanParameter];
            
            if (parameter) 
            {
                // we found one!
                // single slash unicode sequences need to be decoded on reading
                [parameters addObject:[parameter stringByDecodingUnicodeSequences]];
                
                // skip any trailing whitespace
                [self _scanWhitespace];
                
                if (_characters[_currentIndex] == ',') 
                {
                    // consume the comma, but loop again
                    _currentIndex++;
                } 
                else if (_characters[_currentIndex] == ')') 
                {
                    // comsume the closing paren and break
                    _currentIndex++;
                    break;
                } 
                else 
                {
                    // some other character = not syntactically valid = exit
                    return NO;
                }
            } 
            else 
            {
                // we were unable to scan a valid parameter
                // therefore something must be wrong and we should exit
                return NO;
            }
        }
    }
    
    if ([parameters count] > 0) {
        NSString *macroName = [_charactersAsString substringWithRange:range];    
        NSArray *expectedParameters = [_validMacros objectForKey:macroName];
        if ([expectedParameters count] == [parameters count]) 
        {
            // hooray, we successfully scanned!
            
            DTLocalizableStringEntry *entry = [[DTLocalizableStringEntry alloc] init];
            for (NSUInteger i = 0; i < [parameters count]; ++i) 
            {
                NSString *property = [expectedParameters objectAtIndex:i];
                NSString *value = [parameters objectAtIndex:i];
                
                if ([property isEqualToString:@"rawKey"]) {
                    entry.rawKey = value;
                } else if ([property isEqualToString:@"comment"]) {
                    [entry setComment:value];
                } else if ([property isEqualToString:@"tableName"]) {
                    entry.tableName = value;
                } else if ([property isEqualToString:@"bundle"]) {
                    entry.bundle = value;
                } else {
                    [entry setValue:value forKey:property];
                }
            }
            
            if (_entryFoundCallback)
            {
                _entryFoundCallback(entry);
            }
            
            return YES;
        } 
        else 
        {
            NSLog(@"mismatch of parameters for %@ macro", macroName);
        }
    }
    
    return NO;
}

@end
