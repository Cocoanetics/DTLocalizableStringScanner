
//
//  DTLocalizableStringAggregator.m
//  genstrings2
//
//  Created by Oliver Drobnik on 02.01.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import "DTLocalizableStringAggregator.h"
#import "DTLocalizableStringScanner.h"
#import "DTLocalizableStringTable.h"
#import "DTLocalizableStringEntry.h"
#import "NSString+DTLocalizableStringScanner.h"
#import "NSScanner+DTLocalizableStringScanner.h"

@interface DTLocalizableStringAggregator ()

- (void)addEntryToTables:(DTLocalizableStringEntry *)entry;

@end

@implementation DTLocalizableStringAggregator
{
    NSArray *_fileURLs;
    NSMutableDictionary *_stringTables;
    
    NSOperationQueue *_processingQueue;
    dispatch_queue_t _tableQueue;
}

#pragma mark properties

@synthesize wantsPositionalParameters = _wantsPositionalParameters;
@synthesize tablesToSkip = _tablesToSkip;
@synthesize customMacroPrefix = _customMacroPrefix;

- (id)initWithFileURLs:(NSArray *)fileURLs
{
    self = [super init];
    if (self)
    {
        _fileURLs = fileURLs;
        
        _tableQueue = dispatch_queue_create("DTLocalizableStringAggregator", 0);
        
        _processingQueue = [[NSOperationQueue alloc] init];
        [_processingQueue setMaxConcurrentOperationCount:10];
    }
    return self;
}

- (void)dealloc 
{
	dispatch_release(_tableQueue);
}

- (NSDictionary *)validMacros {
    NSArray *prefixes = [NSArray arrayWithObjects:@"NSLocalizedString", @"CFCopyLocalizedString", _customMacroPrefix, nil];
    NSArray *suffixes = [NSArray arrayWithObjects:
                         @"(key, comment)",
                         @"FromTable(key, tableName, comment)",
                         @"FromTableInBundle(key, tableName, bundle, comment)",
                         @"WithDefaultValue(key, tableName, bundle, value, comment)", nil];
	
	
	// make a string from all names
	NSString *allChars = [prefixes componentsJoinedByString:@""];
	
	// add the possible suffixes
	allChars = [allChars stringByAppendingString:@"FromTableInBundleWithDefaultValue"];
	
	// make character set from that
	NSMutableCharacterSet *validMacroChars = [NSMutableCharacterSet characterSetWithCharactersInString:allChars];
	
    NSMutableDictionary *validMacros = [NSMutableDictionary dictionary];
    for (NSString *prefix in prefixes) 
	{
        for (NSString *suffix in suffixes) 
		{
            NSString *macroTemplate = [prefix stringByAppendingString:suffix];
            
            NSString *macroName = nil;
            NSArray *parameters = nil;
            
            NSScanner *scanner = [NSScanner scannerWithString:macroTemplate];
            
            if ([scanner scanMacro:&macroName validMacroCharacters:validMacroChars andParameters:&parameters parametersAreBare:YES]) 
			{
                if (macroName && parameters) 
				{
                    [validMacros setObject:parameters forKey:macroName];
                }
            } 
			else 
			{
                NSLog(@"Invalid Macro: %@", macroTemplate);
            }
        }
    }
    
    return validMacros;
}

- (void)processFiles
{
    NSDictionary *validMacros = [self validMacros];
    
    // create one block for each file
    for (NSURL *oneFile in _fileURLs)
    {
        
        DTLocalizableStringScanner *scanner = [[DTLocalizableStringScanner alloc] initWithContentsOfURL:oneFile validMacros:validMacros];
        [scanner setEntryFoundCallback:^(DTLocalizableStringEntry *entry) {
            dispatch_async(_tableQueue, ^{
                [self addEntryToTables:entry];
            });
        }];
        
        [_processingQueue addOperation:scanner];
    }
    
    [_processingQueue waitUntilAllOperationsAreFinished];
}

- (void)addEntryToTables:(DTLocalizableStringEntry *)entry
{
    NSAssert(dispatch_get_current_queue() == _tableQueue, @"method called from invalid queue");
    if (!_stringTables)
    {
        _stringTables = [NSMutableDictionary dictionary];
    }
    
    NSString *tableName = [entry tableName];
	
    BOOL shouldSkip = [_tablesToSkip containsObject:tableName];
    
    if (!shouldSkip)
    {
        // find the string table for this token, or create it
        DTLocalizableStringTable *table = [_stringTables objectForKey:tableName];
        if (!table)
        {
            // need to create it
			table = [[DTLocalizableStringTable alloc] initWithName:tableName];
            [_stringTables setObject:table forKey:tableName];
        }
        
		if (entry.value)
		{
			// ...WithDefaultValue
			if (_wantsPositionalParameters)
			{
				entry.value = [entry.value stringByNumberingFormatPlaceholders];
			}
			
			[table addEntry:entry];
		}
		else
		{
			// all other options use the key and variations thereof
			
			// support for predicate token splitting
			NSArray *keyVariants = [entry.key variantsFromPredicateVariations];
			
			// add all variants
			for (NSString *oneVariant in keyVariants)
			{
				DTLocalizableStringEntry *splitEntry = [entry copy];
				
				NSString *value = oneVariant;
				if (_wantsPositionalParameters)
				{
					value = [oneVariant stringByNumberingFormatPlaceholders];
				}

				// adjust key and value of the new entry
				splitEntry.key = oneVariant;
				splitEntry.value = value;

				// add token to this table
				[table addEntry:splitEntry];
			}
		}
    }
}

- (BOOL)writeStringTablesToFolderAtURL:(NSURL *)URL encoding:(NSStringEncoding)encoding error:(NSError **)error
{
	for (DTLocalizableStringTable *oneTable in [_stringTables allValues])
	{
		if (![oneTable writeToFolderAtURL:URL encoding:encoding error:error])
		{
			return NO;
		}
	}
	
	return YES;
}

@end
