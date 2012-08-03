//
//  NSString+DTStringFileParser.m
//  genstrings2
//
//  Created by Oliver Drobnik on 01.01.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import "NSString+DTLocalizableStringScanner.h"

@implementation NSString (DTStringFileParser)

- (NSString *)stringByNumberingFormatPlaceholders
{
    static dispatch_once_t onceToken;
    static NSRegularExpression *matchNonEscapedPercent = nil;
    dispatch_once(&onceToken, ^{
        matchNonEscapedPercent = [NSRegularExpression regularExpressionWithPattern:@"(?<=[^%]|^)(?:(?:%%)*)(%)(?:[^%]|$)" options:0 error:NULL];
    });
    
    __block NSMutableString *tmpString = nil;
    __block NSUInteger placeholderCount = 0;
    __block NSUInteger lastLocation = 0;
    
    [matchNonEscapedPercent enumerateMatchesInString:self options:0 range:NSMakeRange(0, [self length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        placeholderCount++;
        NSUInteger currentLocation = [match rangeAtIndex:1].location;
        if (placeholderCount >= 2) {
            if (placeholderCount == 2) {
                tmpString = [NSMutableString string];
                [tmpString appendString:[self substringToIndex:lastLocation + 1]];
                [tmpString appendString:@"1$"];
            }
            [tmpString appendString:[self substringWithRange:NSMakeRange(lastLocation + 1, currentLocation - lastLocation)]];
            [tmpString appendFormat:@"%ld$", placeholderCount];
        }
        lastLocation = currentLocation;
    }];
    
    if (placeholderCount > 1)
    {
        [tmpString appendString:[self substringWithRange:NSMakeRange(lastLocation + 1, [self length] - (lastLocation + 1))]];
        return tmpString;
    }
    else
    {
        return self;
    }
}

- (NSArray *)variantsFromPredicateVariations
{
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.charactersToBeSkipped = nil; // we need whitespace too
    
    NSMutableArray *stringParts = [NSMutableArray array];
    
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    // build an array of string parts: NSString, NSArray, NSString ...
    while (![scanner isAtEnd]) 
    {
        NSString *part = nil;
        
        // skip to first [
        if ([scanner scanUpToString:@"%[" intoString:&part])
        {
            [stringParts addObject:part];
        }
        
        // do we have a list?
        if ([scanner scanString:@"%[" intoString:NULL])
        {
            NSString *tokenList = nil;
            
            [stringParts addObject:@"%["];
            
            if ([scanner scanUpToString:@"]" intoString:&tokenList])
            {
                // do we have a closing?
                if ([scanner scanString:@"]" intoString:NULL])
                {
                    // dissove list
                    NSArray *listElements = [tokenList componentsSeparatedByString:@","];
                    NSMutableArray *tmpList = [NSMutableArray array];
                    
                    for (NSString *oneElement in listElements)
                    {
                        [tmpList addObject:[oneElement stringByTrimmingCharactersInSet:whitespaceSet]];
                    }
                    
                    [stringParts addObject:tmpList];
                    
                    [stringParts addObject:@"]"];
                }
            }
        }
    }
    
    NSMutableArray *results = [NSMutableArray array];
    
    // generate all variants
    for (id part in stringParts)
    {
        @autoreleasepool 
        {
            if ([part isKindOfClass:[NSArray class]])
            {
                // this is an array
                NSMutableArray *newResults = [NSMutableArray array];
                
                // copy all previous results and append all elements from array
                if ([results count])
                {
                    for (NSString *oneToken in part)
                    {
                        for (NSString *oneResult in results)
                        {
                            NSMutableString *copiedResult = [oneResult mutableCopy];
                            [copiedResult appendString:oneToken];
                            
                            [newResults addObject:copiedResult];
                        }
                    }
                    
                    // new results replace old ones
                    results = newResults;
                }
                else
                {
                    // there was nothing previous, these tokens become the first results
                    for (NSString *oneToken in part)
                    {
                        [results addObject:[oneToken mutableCopy]];
                    }
                }
            }
            else
            {
                // must be an NSString, append to all previous results
                if ([results count])
                {
                    for (NSMutableString *oneResult in results)
                    {
                        [oneResult appendString:part];
                    }
                }
                else
                {
                    // no results yet, this becomes the first result
                    [results addObject:[part mutableCopy]];
                }
            }
        }
    }
    
    
    // only return array if it has entries
    if ([results count])
    {
        return results;
    }
    else
    {
        return nil;
    }
}

/*
- (NSString *)stringByRemovingSlashEscapes
{
    // a neat little trick from http://stackoverflow.com/a/2099484
    NSData *d = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSString *unescaped = [NSPropertyListSerialization propertyListWithData:d options:NSPropertyListImmutable format:NULL error:NULL];
    
    if (![unescaped isKindOfClass:[NSString class]] || [unescaped length] == 0) 
    {
        // it didn't convert properly
        return self;
    }
    
	// preserve quotes !
	if ([self hasPrefix:@"\""] && [self hasSuffix:@"\""])
	{
		return [NSString stringWithFormat:@"\"%@\"", unescaped];
	}
	
    return unescaped;
}
 */

- (NSString *)stringByDecodingUnicodeSequences
{
    
    if ([self rangeOfString:@"\\" options:NSLiteralSearch].location == NSNotFound) {
        return [self copy];
    }    
    
    NSUInteger length = [self length];
    
    static NSCharacterSet *hex = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hex = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
    });
    
    unichar *characters = calloc(length, sizeof(unichar));
    
    unichar *final = calloc(length+1, sizeof(unichar));
    NSUInteger currentFinalIndex = 0;
    
    [self getCharacters:characters range:NSMakeRange(0, length)];
    
    int decodeCount = 0;
    BOOL isEscaping = NO;
    for (NSUInteger i = 0; i < length; ++i) {
        unichar character = characters[i];
        BOOL addToFinal = YES;
        
        if (isEscaping) 
        {
            if (character == 'U') 
            {
                addToFinal = NO;
                isEscaping = NO;
                decodeCount = 2;
            } 
            else
            {
                final[currentFinalIndex++] = '\\';
				isEscaping = NO;
            }
        }
        else
        {
            if (character == '\\')
            {
                decodeCount = 0;
                addToFinal = NO;
                isEscaping = YES;
            }
            else if ([hex characterIsMember:character] && decodeCount > 0)
            {
                if (i+4 <= length)
                {
                    BOOL canDecode = YES;
                    char tmp[5] = { 0 };
                    for (int j = 0; j < 4; ++j) {
                        // all four characters have to be hex chars
                        unichar tmpC = characters[i+j];
                        if (![hex characterIsMember:tmpC])
                        {
                            canDecode = NO;
                            break;
                        }
                        else
                        {
                            tmp[j] = tmpC & 0xFF;
                        }
                    }
                    
                    if (canDecode)
                    {
                        decodeCount--;
                        
                        character = (unichar)strtol((const char*)tmp, NULL, 16);
                        i += 3;
                    }
                    else
                    {
                        // not all the chars are hex
                        if (decodeCount == 2)
                        {
                            // these were the characters right after the \U
                            final[currentFinalIndex++] = '\\';
                            final[currentFinalIndex++] = 'U';
                        }
                        decodeCount = 0;
                    }
                }
                else
                {
                    // not enough characters to form a full sequence
                    if (decodeCount == 2)
                    {
                        // these were the characters right after the \U
                        final[currentFinalIndex++] = '\\';
                        final[currentFinalIndex++] = 'U';
                    }
                    decodeCount = 0;
                }
            }
            else
            {
                decodeCount = 0;
            }
        }
        
        if (addToFinal)
        {
            final[currentFinalIndex++] = character;
        }
    }
    free(characters);
    NSString *clean = [[NSString alloc] initWithCharacters:final length:currentFinalIndex];
    free(final);
    
    return clean;
}

- (NSString *)stringByReplacingSlashEscapes
{
    if ([self rangeOfString:@"\\" options:NSLiteralSearch].location == NSNotFound) {
        return [self copy];
    }
    
	NSUInteger length = [self length];
    
    unichar *characters = calloc(length, sizeof(unichar));
    unichar *final = calloc(length+1, sizeof(unichar));
	
	[self getCharacters:characters range:NSMakeRange(0, length)];
	
	NSUInteger outChars = 0;
	
	BOOL inEscapeSequence = NO;
	BOOL inOctalCode = NO;
	BOOL inHexCode = NO;
	
	unsigned long long scannedCode = 0;
	
	for (NSUInteger idx=0; idx<length;)
	{
		unichar character = characters[idx];
		
		if (inEscapeSequence)
		{
			if (inHexCode)
			{
				int value;
				if (character>='0' && character<='9')
				{
					value = character - '0';
				}
				else if (character>='A' && character<='F')
				{
					value = character - 'A' + 10;
				}
				else if (character>='a' && character<='f')
				{
					value = character - 'a' + 10;
				}
				else
				{
					// hex code ended
					final[outChars++] = scannedCode;
					
					inHexCode = NO;
					inEscapeSequence = NO;
					
					// go back to loop start and now deal with this character
					continue;
				}
				
				scannedCode = scannedCode * 16 + value;
			}
			
			if (character>='0' && character<='9')
			{
				if (!inOctalCode)
				{
					// first octal digit!
					inOctalCode = YES;
					scannedCode = 0;
				}
				
				// add this digit to code
				scannedCode = scannedCode * 8 + (character - '0');
			}
			else
			{
				if (inOctalCode)
				{
					// this character ended the octal code
					final[outChars++] = scannedCode;
					
					inOctalCode = NO;
					inEscapeSequence = NO;
					
					// go back to loop start and now deal with this character
					continue;
				}
				
				switch (character) 
				{
					case 'n':
					{
						character = '\n';
						break;
					}
						
					case 't':
					{
						character = '\t';
						break;
					}
						
					case 'v':
					{
						character = '\v';
						break;
					}
						
					case 'b':
					{
						character = '\b';
						break;
					}
						
					case 'r':
					{
						character = '\r';
						break;
					}
						
					case 'f':
					{
						character = '\f';
						break;
					}
						
					case 'a':
					{
						character = 'a';
						break;
					}
						
					case '\\':
					{
						character = '\\';
						break;
					}
						
					case '\?':
					{
						character = '\?';
						break;
					}
						
					case '\'':
					{
						character = '\'';
						break;
					}
						
					case '\"':
					{
						character = '\"';
						break;
					}

					case 'x':
					{
						// hex number follows
						inHexCode = YES;
						scannedCode = 0;
						break;
					}
						
					default:
					{
						// unknown escape sequence
						// copy it like it is
						final[outChars++] = '\\';
					}
				}

				// add the unescaped character
				final[outChars++] = character;
				
				if (!inHexCode)
				{
					// all other sequences are done here
					inEscapeSequence = NO;
				}
			}
		}
		else
		{
			if (characters[idx] == '\\')
			{
				// escaped sequence begins
				inEscapeSequence = YES;
			}
			else
			{
				// just copy character
				final[outChars++] = character;
			}
		}
		
		idx++;
	}
	
	free(characters);
    NSString *clean = [[NSString alloc] initWithCharacters:final length:outChars];
    free(final);
    
    return clean;
}

- (NSString *)stringByAddingSlashEscapes
{
	NSUInteger length = [self length];
    
    unichar *characters = calloc(length, sizeof(unichar));
    unichar *final = calloc(length*2+1, sizeof(unichar));
	
	[self getCharacters:characters range:NSMakeRange(0, length)];
	
	NSUInteger outChars = 0;
	
	for (NSUInteger idx=0; idx<length;idx++)
	{
		unichar character = characters[idx];
		
		switch (character) 
		{
			case '\n':
			{
				final[outChars++] = '\\';
				final[outChars++] = 'n';
				break;
			}
				
			case '\t':
			{
				final[outChars++] = '\\';
				final[outChars++] = 't';
				break;
			}
				
			case '\v':
			{
				final[outChars++] = '\\';
				final[outChars++] = 'v';
				break;
			}
				
			case '\b':
			{
				final[outChars++] = '\\';
				final[outChars++] = 'b';
				break;
			}
				
			case '\r':
			{
				final[outChars++] = '\\';
				final[outChars++] =  'r';
				break;
			}
				
			case '\f':
			{
				final[outChars++] = '\\';
				final[outChars++] =  'f';
				break;
			}
				
			case '\a':
			{
				final[outChars++] = '\\';
				final[outChars++] =  'a';
				break;
			}
				
			case '\\':
			{
				final[outChars++] = '\\';
				final[outChars++] =  '\\';
				break;
			}
				
			case '\?':
			{
				final[outChars++] = '\\';
				final[outChars++] = '\?';
				break;
			}
				
			case '\'':
			{
				final[outChars++] = '\\';
				final[outChars++] =  '\'';
				break;
			}
				
			case '\"':
			{
				final[outChars++] = '\\';
				final[outChars++] =  '\"';
				break;
			}
				
			default:
			{
				final[outChars++] = character;
			}
		}
	}
	
	free(characters);
    NSString *clean = [[NSString alloc] initWithCharacters:final length:outChars];
    free(final);
    
    return clean;
}

@end
