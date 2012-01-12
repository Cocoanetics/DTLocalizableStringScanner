//
//  DTLocalizableStringScanner.m
//  genstrings2
//
//  Created by Oliver Drobnik on 29.12.11.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import "DTLocalizableStringScanner.h"
#import "DTLocalizableStringEntry.h"
#import "NSScanner+DTLocalizableStringScanner.h"
#import "NSString+DTLocalizableStringScanner.h"

@interface DTLocalizableStringScanner ()

- (NSCharacterSet *)validMacroCharacters;

@end

@implementation DTLocalizableStringScanner
{
    NSString *_string;
    NSURL *_url;
    NSDictionary *_validMacros;
	NSSet *_macroNameCache;
	
	DTLocalizableStringEntryFoundCallback _entryFoundCallback;
}

- (id)initWithContentsOfURL:(NSURL *)url validMacros:(NSDictionary *)validMacros
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
        _validMacros = validMacros;
		
		// fast lookup of macros
		_macroNameCache = [[NSSet alloc] initWithArray:[_validMacros allKeys]];
    }
    
    return self;
}

- (void)main
{
    NSScanner *scanner = [NSScanner scannerWithString:_string];
    
    NSCharacterSet *validMacroCharacters = [self validMacroCharacters];
    
    while (![scanner isAtEnd]) 
    {
		@autoreleasepool 
		{
			NSString *macro = nil;
			NSArray *parameters = nil;
			
			// skip to next macro
			[scanner scanUpToCharactersFromSet:validMacroCharacters intoString:NULL];
			
			// this should be a macro
			if ([scanner scanCharactersFromSet:validMacroCharacters intoString:&macro])
			{
				if ([_macroNameCache containsObject:macro])
				{
					if ([scanner scanMacroParameters:&parameters parametersAreBare:NO])
					{
						NSArray *paramNames = [_validMacros objectForKey:macro];
						
						if (paramNames)
						{
							// ignore macros that are not registered
							
							if ([paramNames count] == [parameters count])
							{
								// scanned parameters must match up with registered names
								DTLocalizableStringEntry *entry = [[DTLocalizableStringEntry alloc] init];
								
								for (NSUInteger i=0; i<[paramNames count]; i++)
								{
									NSString *paramName = [paramNames objectAtIndex:i];
									NSString *paramValue = [parameters objectAtIndex:i];
									
									[entry setValue:paramValue forKey:paramName];
								}
								
								// key is mandatory
								if ([entry.key length])
								{
									if (_entryFoundCallback)
									{
										_entryFoundCallback(entry);
									}
								}
								else
								{
									NSLog(@"Illegal Key on %@", entry);
								}
							}
							else
							{
								//NSLog(@"different parameter count than registered %@ %@", paramNames, parameters);
								// macro parameter count is different scanned versus registered, ignoring it
							}
						}
					}
				}
			}
		}
    }
}

#pragma mark Properties

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

@synthesize entryFoundCallback=_entryFoundCallback;

@end
