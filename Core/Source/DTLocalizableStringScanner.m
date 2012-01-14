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

- (NSCharacterSet *)validMacroCharacters;

- (BOOL)_scanMacro;

@end

@implementation DTLocalizableStringScanner
{
    NSURL *_url;
    NSDictionary *_validMacros;
    NSCharacterSet *_validMacroCharacters;
    
    NSUInteger _minMacroNameLength;
    NSUInteger _maxMacroNameLength;
    
    unichar *_characters;
    NSUInteger _stringLength;
    NSUInteger _currentIndex;
}

@synthesize entryFoundCallback=_entryFoundCallback;

- (id)initWithContentsOfURL:(NSURL *)url validMacros:(NSDictionary *)validMacros
{
    self = [super init];
    
    if (self)
    {
        NSString *string = [[NSString alloc] initWithContentsOfURL:url usedEncoding:NULL error:NULL];
        
        if (!string)
        {
            return nil;
        }
        
        _stringLength = [string length];
        _characters = calloc(_stringLength, sizeof(unichar));
        [string getCharacters:_characters range:NSMakeRange(0, _stringLength)];
        _currentIndex = 0;
        
        _url = [url copy]; // to have a reference later
        _validMacros = validMacros;
        
        // get longest and shortest macro name
        _minMacroNameLength = NSIntegerMax;
        _maxMacroNameLength = 0;
        
        for (NSString *oneMacro in [_validMacros allKeys])
        {
            NSUInteger l = [oneMacro length];
            
            if (l<_minMacroNameLength)
            {
                _minMacroNameLength = l;
            }
            else if (l>_maxMacroNameLength)
            {
                _maxMacroNameLength = l;
            }
        }
    }
    
    return self;
}

- (void)dealloc {
    if (_characters) {
        free(_characters);
    }
}

- (void)main
{
    @autoreleasepool {
        NSCharacterSet *macroCharacters = [self validMacroCharacters];
        while (_currentIndex < _stringLength) {
            unichar character = _characters[_currentIndex];
            if ([macroCharacters characterIsMember:character]) {
                
                NSUInteger macroStartIndex = _currentIndex;
                if (![self _scanMacro]) {
                    _currentIndex = macroStartIndex + 1;
                }
            } else {
                // not a character that can be part of a macro name; keep going
                _currentIndex++;
            }
        }
    }
}

#define IS_WHITESPACE(_c) ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:(_c)])

- (void)_scanWhitespace {
    while (IS_WHITESPACE(_characters[_currentIndex])) {
        _currentIndex++;
    }
}

- (NSString *)_scanQuotedString {
    NSMutableString *clean = [NSMutableString stringWithCapacity:100];
    
    // handle the opening quote
    if (_characters[_currentIndex] == '"') {
        _currentIndex++;
    }
    
    BOOL isEscaping = NO;
    BOOL keepGoing = YES;
    while (keepGoing) {
        unichar character = _characters[_currentIndex];
        
        if (isEscaping) {
            isEscaping = NO;
        } else {
            if (character == '\\') {
                unichar nextCharacter = _characters[_currentIndex+1];
                if (nextCharacter != 'u' && nextCharacter != 'U') {
                    isEscaping = YES;
                } else {
                    // prefer the upper-case variant
                    character = 'U';
                }
            } else if (character == '"') {
                keepGoing = NO;
            }
        }
        
        if (keepGoing)
        {
            [clean appendFormat:@"%C", character];
        }
        
        _currentIndex++;
    }
    
    return clean;
}

- (NSString *)_scanParameter 
{
    // TODO: handle comments in parameters
    // eg: NSLocalizedString("Something", /* blah */ nil)
    NSUInteger parameterStartIndex = _currentIndex;
    BOOL keepGoing = YES;
    NSString *quotedString = nil;
    
    NSInteger parenCount = 0;
    
    while (keepGoing) {
        unichar character = _characters[_currentIndex];
        if (character == ',') 
        {
            keepGoing = NO;
        } else if (character == '(') 
        {
            _currentIndex++;
            parenCount++;
        } else if (character == ')') 
        {
            parenCount--;
            if (parenCount >= 0) 
            {
                _currentIndex++;
            } else 
            {
                keepGoing = NO;
            }
        } else if (character == '"') 
        {
            quotedString = [self _scanQuotedString];
        } else 
        {
            _currentIndex++;
        }
    }
    
    if (quotedString) 
    {
        return quotedString;
    }
    
    NSUInteger length = _currentIndex - parameterStartIndex;
    return [[NSString alloc] initWithCharactersNoCopy:(_characters+parameterStartIndex) length:length freeWhenDone:NO];
}

- (BOOL)_scanMacro 
{
    NSUInteger macroStartIndex = _currentIndex;
    NSCharacterSet *macroCharacters = [self validMacroCharacters];
    
    // read as much of the macroName as possible
    while ([macroCharacters characterIsMember:_characters[_currentIndex]]) 
    {
        _currentIndex++;
    }
    
    // pull out the macroName:
    NSUInteger macroNameLength = _currentIndex - macroStartIndex;
    
    if (macroNameLength < _minMacroNameLength || macroNameLength > _maxMacroNameLength)
    {
        // too short or too long to be one of our macros
        return NO;
    }
    
    NSString *macroName = [[NSString alloc] initWithCharactersNoCopy:(_characters+macroStartIndex) length:macroNameLength freeWhenDone:NO];
    
    if ([_validMacros objectForKey:macroName]) 
    {
        // we found a macro name!

        NSMutableArray *parameters = [[NSMutableArray alloc] initWithCapacity:10];

        // skip any whitespace between here and the (
        [self _scanWhitespace];
        
        if (_characters[_currentIndex] == '(') 
        {
            // read the opening parenthesis
            _currentIndex++;
            
            while (1) 
            {
                // skip any leading whitespace
                [self _scanWhitespace];
                
                // scan a parameter
                NSString *parameter = [self _scanParameter];
                
                if (parameter) 
                {
                    // we found one!
                    [parameters addObject:parameter];
                    
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
            };
        }
        
        NSArray *expectedParameters = [_validMacros objectForKey:macroName];
        if ([expectedParameters count] == [parameters count]) 
        {
            // hooray, we successfully scanned!
            
            DTLocalizableStringEntry *entry = [[DTLocalizableStringEntry alloc] init];
            for (NSUInteger i = 0; i < [parameters count]; ++i) 
            {
                NSString *property = [expectedParameters objectAtIndex:i];
                NSString *value = [parameters objectAtIndex:i];
                [entry setValue:value forKey:property];
            }
            
            if (_entryFoundCallback)
            {
                _entryFoundCallback(entry);
            }
            
            return YES;
        }
        
    }
    
    return NO;
}

#pragma mark Properties

- (NSCharacterSet *)validMacroCharacters
{
    if (!_validMacroCharacters) {
        // make a string from all names
        NSString *allChars = [[_validMacros allKeys] componentsJoinedByString:@""];
        
        _validMacroCharacters = [NSCharacterSet characterSetWithCharactersInString:allChars];
	}
	return _validMacroCharacters;
}

@end
