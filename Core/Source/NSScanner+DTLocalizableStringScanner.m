//
//  NSScanner+DTLocalizableStringScanner.m
//  genstrings2
//
//  Created by Oliver Drobnik on 29.12.11.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import "NSScanner+DTLocalizableStringScanner.h"

@implementation NSScanner (DTLocalizableStringScanner)

- (BOOL)scanQuotedAndEscapedString:(NSString **)value
{
    NSUInteger positionBeforeScanning = [self scanLocation];
    NSCharacterSet *quoteOrSlash = [NSCharacterSet characterSetWithCharactersInString:@"\\\""];
    
    BOOL seenCFSTR = NO;
    
    // skip AT, it's optional (at least for comments, but we don't care)
    if (![self scanString:@"@" intoString:NULL])
    {
        // could be a CF string macro
        if ([self scanString:@"CFSTR" intoString:NULL])
        {
            seenCFSTR = YES;
        }
        
    }
    
    // CFSTR expects opening bracket
    if (seenCFSTR && ![self scanString:@"(" intoString:NULL])
    {
        // missing (
        self.scanLocation = positionBeforeScanning;
        return NO;
    }
    
    if (![self scanString:@"\"" intoString:NULL])
    {
		// could be a nil, that's also acceptable
		if ([self scanString:@"nil" intoString:NULL])
		{
			if (value)
			{
				*value = @"";
			}
			return YES;
		}
		else
		{
			// missing @ and opening quote
			self.scanLocation = positionBeforeScanning;
			return NO;
		}
    }
	
	// preserve the setting, the quote itself does not skip
    NSCharacterSet *charactersToBeSkipped = self.charactersToBeSkipped;
	self.charactersToBeSkipped = nil;
	
    NSMutableString *tmpString = [NSMutableString string];
    
    BOOL needsLoop = NO;
    
    do
    {
        needsLoop = NO;
		NSString *part = nil;
		
		if ([self scanUpToCharactersFromSet:quoteOrSlash intoString:&part])
		{
            [tmpString appendString:part];
			needsLoop = YES;
		}
		
		if ([self scanCharactersFromSet:quoteOrSlash intoString:&part])
		{
			while ([part hasSuffix:@"\""]) 
			{
				if ([part hasPrefix:@"\""])
				{
					needsLoop = NO;
					part = nil;
					break;
				}
				else if ([part hasPrefix:@"\\\""])
				{
					[tmpString appendString:@"\\\""];
					part = [part substringFromIndex:2];
				}
			}
			
			// add remaining stuff
			if (part)
			{
				[tmpString appendString:part];
			}
		}
		
//		
//		if ([self scanCharactersFromSet:quoteOrSlash intoString:&part])
//		{
//			if ([part hasPrefix:@"\""])
//			{
//				break; // we're done
//			}
//			
//		}
//		
//		if ([self scanString:@"\"" intoString:NULL])
//		{
//			break;
//		}
//		else if ([self scanString:@"\\\"" intoString:NULL])
//		{
//			// escaped quote
//			[tmpString appendString:@"\\\""];
//			needsLoop = YES;
//		}
//		else 
    } while (needsLoop);
	
	// restore previous setting
	self.charactersToBeSkipped = charactersToBeSkipped;
    
//    if (![self scanString:@"\"" intoString:NULL])
//    {
//        // missing closing quote
//        self.scanLocation = positionBeforeScanning;
//        return NO;
//    }
    
    // CFSTR expects closing bracket
    if (seenCFSTR && ![self scanString:@")" intoString:NULL])
    {
        // missing (
        self.scanLocation = positionBeforeScanning;
        return NO;
    }
	
    
    if (value)
    {
        *value = tmpString;
    }
    
    return YES;
}

- (BOOL)scanMacroParameters:(NSArray **)parameters parametersAreBare:(BOOL)bare
{
	NSUInteger previousScanLocation = [self scanLocation];

	if (![self scanString:@"(" intoString:NULL])
	{
		// opening bracket missing
		self.scanLocation = previousScanLocation;
		return NO;
	}
	
	BOOL closingBracketEncountered = NO;
	
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	while (!closingBracketEncountered && ![self isAtEnd])
	{
		NSString *parameter = nil;
		
		if (bare)
		{
			if ([self scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&parameter])
			{
				[tmpArray addObject:parameter];
			}
		}
		else
		{
			if ([self scanQuotedAndEscapedString:&parameter])
			{
				[tmpArray addObject:parameter];
			}
			else
			{
				// try to skip this parameter, might be a bundle pointer, which is not a string literal
				// TODO: make this skipping of code more robust
				NSString *code = nil;
				if ([self scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"),"]
										 intoString:&code])
				{
					[tmpArray addObject:@""]; // need to add something so that parameters don't shift
				}
			}
		}
		
		if ([self scanString:@")" intoString:NULL])
		{
			closingBracketEncountered = YES;
			continue;
		}
		
		if (![self scanString:@"," intoString:NULL])
		{
			// there should be a comma
			self.scanLocation = previousScanLocation;
			return NO;
		}
	}
	
	if (!closingBracketEncountered)
	{
		// closing bracket missing
		self.scanLocation = previousScanLocation;
		return NO;
	}
	
	if (parameters)
	{
		*parameters = tmpArray;
	}
	
//	NSString *scannedString = [[self string] substringWithRange:NSMakeRange(previousScanLocation, self.scanLocation - previousScanLocation)];
//	NSLog(@"%@", scannedString);						   
	
	return YES;
}

- (BOOL)scanMacro:(NSString **)macro  validMacroCharacters:(NSCharacterSet *)macroCharacterSet andParameters:(NSArray **)parameters parametersAreBare:(BOOL)bare
{
	NSString *macroName = nil;
	NSUInteger previousScanLocation = [self scanLocation];
	
	if (!macroCharacterSet)
	{
		macroCharacterSet = [NSCharacterSet alphanumericCharacterSet];
	}
	
	if (![self scanCharactersFromSet:macroCharacterSet intoString:&macroName])
	{
		self.scanLocation = previousScanLocation;
		return NO;
	}
	
	if (![self scanString:@"(" intoString:NULL])
	{
		// opening bracket missing
		self.scanLocation = previousScanLocation;
		return NO;
	}
	
	BOOL closingBracketEncountered = NO;
	
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	while (!closingBracketEncountered && ![self isAtEnd])
	{
		NSString *parameter = nil;
		
		if (bare)
		{
			if ([self scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&parameter])
			{
				[tmpArray addObject:parameter];
			}
		}
		else
		{
			if ([self scanQuotedAndEscapedString:&parameter])
			{
				[tmpArray addObject:parameter];
			}
			else
			{
				// try to skip this parameter, might be a bundle pointer, which is not a string literal
				// TODO: make this skipping of code more robust
				NSString *code = nil;
				if ([self scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"),"]
										 intoString:&code])
				{
					[tmpArray addObject:@""]; // need to add something so that parameters don't shift
				}
			}
		}
		
		if ([self scanString:@")" intoString:NULL])
		{
			closingBracketEncountered = YES;
			continue;
		}
		
		if (![self scanString:@"," intoString:NULL])
		{
			// there should be a comma
			self.scanLocation = previousScanLocation;
			return NO;
		}
	}
	
	if (!closingBracketEncountered)
	{
		// closing bracket missing
		self.scanLocation = previousScanLocation;
		return NO;
	}
	
	if (macro)
	{
		*macro = macroName;
	}
	
	if (parameters)
	{
		*parameters = tmpArray;
	}
	
	return YES;
}

@end
