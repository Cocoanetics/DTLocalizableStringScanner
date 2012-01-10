//
//  DTLocalizableStringScanner.m
//  genstrings2
//
//  Created by Oliver Drobnik on 29.12.11.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import "DTLocalizableStringScanner.h"
#import "NSScanner+DTLocalizableStringScanner.h"
#import "NSString+DTLocalizableStringScanner.h"

@interface DTLocalizableStringScanner ()

@property (nonatomic, retain) NSMutableDictionary *validMacros;

- (NSCharacterSet *)validMacroCharacters;

@end

@implementation DTLocalizableStringScanner
{
    NSString *_string;
    NSURL *_url;
    NSMutableDictionary *_validMacros;
    
    // lookup bitmask what delegate methods are implemented
	struct 
	{
		unsigned int delegateSupportsStart:1;
		unsigned int delegateSupportsEnd:1;
        unsigned int delegateSupportsDidFindToken:1;
	} _delegateFlags;
    
    __unsafe_unretained id <DTLocalizableStringScannerDelegate> _delegate;
}

- (id)initWithContentsOfURL:(NSURL *)url
{
    self = [super init];
    
    if (self)
    {
        _string = [[NSString alloc] initWithContentsOfURL:url usedEncoding:NULL error:NULL];
        
        if (!_string)
        {
            return nil;
        }
        
        _url = [url copy]; // to have a reference later
    }
    
    return self;
}

- (BOOL)scanFile
{
    if (_delegateFlags.delegateSupportsStart)
    {
        [_delegate localizableStringScannerDidStartDocument:self];
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:_string];
    
    // register the default macros if there is no custom prefix
    if (![_validMacros count])
    {
        [self registerDefaultMacros];
    }
    
    NSCharacterSet *validMacroCharacters = [self validMacroCharacters];
    
    while (![scanner isAtEnd]) 
    {
        NSString *macro = nil;
        NSArray *parameters = nil;
        
        // skip to next word
        [scanner scanUpToCharactersFromSet:validMacroCharacters intoString:NULL];
        
        if ([scanner scanMacro:&macro andParameters:&parameters parametersAreBare:NO])
        {
            NSArray *paramNames = [_validMacros objectForKey:macro];
            
            if (paramNames)
            {
                // ignore macros that are not registered
                
                if ([paramNames count] == [parameters count])
                {
                    // scanned parameters must match up with registered names
                    NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
                    
                    for (NSUInteger i=0; i<[paramNames count]; i++)
                    {
                        NSString *paramName = [paramNames objectAtIndex:i];
                        NSString *paramValue = [parameters objectAtIndex:i];
                        
                        [tmpDict setObject:paramValue forKey:paramName];
                    }
                    
                    if (_delegateFlags.delegateSupportsDidFindToken)
                    {
                        [_delegate localizableStringScanner:self
                                               didFindToken:tmpDict];
                    }
                }
                else
                {
                    // macro parameter count is different scanned versus registered, ignoring it
                }
            }
        }
        else
        {
            // is a word, but not a valid macro
            [scanner scanCharactersFromSet:validMacroCharacters intoString:NULL];
        }
    }
    
    if (_delegateFlags.delegateSupportsEnd)
    {
        [_delegate localizableStringScannerDidEndDocument:self];
    }
    
    return YES;
}


#pragma mark Macro handling
- (void)registerMacrosWithPrefix:(NSString *)macroPrefix
{
    self.validMacros = nil;

    NSArray *defaultMacros = [NSArray arrayWithObjects:@"NSLocalizedString(key, comment)",
                              @"NSLocalizedStringFromTable(key, tbl, comment)",
                              @"NSLocalizedStringFromTableInBundle(key, tbl, bundle, comment)",
                              @"NSLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment)", nil];
    
    for (NSString *macro in defaultMacros)
    {
        NSString *usedMacro;
        
        if (macroPrefix)
        {
           usedMacro = [macro stringByReplacingOccurrencesOfString:@"NSLocalizedString" withString:macroPrefix];
        }
        else
        {
            usedMacro = macro;
        }
        
        [self registerMacroWithPrototypeString:usedMacro];
    }
}

- (void)registerDefaultMacros
{
    [self registerMacrosWithPrefix:nil];
    
    // register old CF style macros
    [self registerMacroWithPrototypeString:@"CFCopyLocalizedString(key, comment)"];
    [self registerMacroWithPrototypeString:@"CFCopyLocalizedStringFromTable(key, tbl, comment)"];
    [self registerMacroWithPrototypeString:@"CFCopyLocalizedStringFromTableInBundle(key, tbl, bundle, comment)"];
    [self registerMacroWithPrototypeString:@"CFCopyLocalizedStringWithDefaultValue(key, tbl, bundle, value, comment)"];    
}

- (void)registerMacroWithPrototypeString:(NSString *)prototypeString
{
    NSString *macroName = nil;
    NSArray *parameters = nil;
    
    NSScanner *scanner = [NSScanner scannerWithString:prototypeString];
    
    if ([scanner scanMacro:&macroName andParameters:&parameters parametersAreBare:YES])
    {
        if (macroName && parameters)
        {
            [self.validMacros setObject:parameters forKey:macroName];
        }
    }
    else
    {
        NSLog(@"Invalid Macro: %@", prototypeString);
    }
}

#pragma mark Properties

- (NSMutableDictionary *)validMacros
{
    if (!_validMacros)
    {
        _validMacros = [[NSMutableDictionary alloc] init];
    }
    
    return _validMacros;
}

- (NSCharacterSet *)validMacroCharacters
{
	// make a string from all names
	NSString *allChars = [[_validMacros allKeys] componentsJoinedByString:@""];

	// make character set from that
	NSMutableCharacterSet *tmpSet = [NSMutableCharacterSet characterSetWithCharactersInString:allChars];
	
	// remove whitespace
	NSCharacterSet *nonWhiteSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
	[tmpSet formIntersectionWithCharacterSet:nonWhiteSet];
	
	return tmpSet;
}

- (void)setDelegate:(id<DTLocalizableStringScannerDelegate>)delegate
{
    if (_delegate != delegate)
    {
        _delegateFlags.delegateSupportsStart = [delegate respondsToSelector:@selector(localizableStringScannerDidStartDocument:)];
        _delegateFlags.delegateSupportsEnd = [delegate respondsToSelector:@selector(localizableStringScannerDidEndDocument:)];   
        _delegateFlags.delegateSupportsDidFindToken = [delegate respondsToSelector:@selector(localizableStringScanner:didFindToken:)];
        
        _delegate = delegate;
    }
}

@synthesize validMacros = _validMacros;
@synthesize delegate = _delegate;

@end
