
//
//  DTLocalizableStringAggregator.m
//  genstrings2
//
//  Created by Oliver Drobnik on 02.01.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import "DTLocalizableStringAggregator.h"
#import "DTLocalizableStringScanner.h"
#import "DTLocalizableStringEntry.h"
#import "NSString+DTLocalizableStringScanner.h"
#import "NSScanner+DTLocalizableStringScanner.h"

@interface DTLocalizableStringAggregator ()

- (void)addEntryToTables:(DTLocalizableStringEntry *)entry;
- (void)writeStringTables;

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
@synthesize outputFolderURL = _outputFolderURL;
@synthesize customMacroPrefix = _customMacroPrefix;
@synthesize outputStringEncoding = _outputStringEncoding;

- (id)initWithFileURLs:(NSArray *)fileURLs
{
    self = [super init];
    if (self)
    {
        _fileURLs = fileURLs;
        
        _tableQueue = dispatch_queue_create("DTLocalizableStringAggregator", 0);
        
        _processingQueue = [[NSOperationQueue alloc] init];
        [_processingQueue setMaxConcurrentOperationCount:10];
        
        // default encoding
        _outputStringEncoding = NSUTF16StringEncoding;
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
    // set output dir to current working dir if not set
    if (!_outputFolderURL)
    {
        NSString *cwd = [[NSFileManager defaultManager] currentDirectoryPath];
        _outputFolderURL = [NSURL fileURLWithPath:cwd];
    }
    
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
    
    [self writeStringTables];
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
        NSMutableArray *table = [_stringTables objectForKey:tableName];
        if (!table)
        {
            // need to create it
            table = [NSMutableArray array];
            [_stringTables setObject:table forKey:tableName];
        }
        
        // add token to this table
        [table addObject:entry];
    }
}

- (void)writeStringTables
{
    NSArray *tableNames = [_stringTables allKeys];
    
    for (NSString *oneTableName in tableNames)
    {
        NSString *fileName = [oneTableName stringByAppendingPathExtension:@"strings"];
        NSURL *tableURL = [NSURL URLWithString:fileName relativeToURL:_outputFolderURL];
        
        NSArray *entries = [_stringTables objectForKey:oneTableName];
        
        NSMutableString *tmpString = [NSMutableString string];
        
        for (DTLocalizableStringEntry *entry in entries)
        {
            NSString *comment = [entry comment];
            NSString *key = [entry key];
			NSString *value = [entry value];
			
			// output comment
            [tmpString appendFormat:@"/* %@ */\n", comment];
			
			if (value)
			{
				// ...WithDefaultValue
				
				NSString *outputValue = value;
				if (_wantsPositionalParameters)
				{
					outputValue = [value stringByNumberingFormatPlaceholders];
				}
				
				[tmpString appendFormat:@"\"%@\" = \"%@\";\n", key, outputValue];
			}
			else
			{
				// all other options use the key and variations thereof
				
				// support for predicate token splitting
				NSArray *keyVariants = [key variantsFromPredicateVariations];
				
				// output all variants
				for (NSString *oneVariant in keyVariants)
				{
					NSString *value = oneVariant;
					if (_wantsPositionalParameters)
					{
						value = [oneVariant stringByNumberingFormatPlaceholders];
					}
					
					[tmpString appendFormat:@"\"%@\" = \"%@\";\n", oneVariant, value];
				}
			}
            
            
            [tmpString appendString:@"\n"];
        }
        
        NSError *error = nil;
        if (![tmpString writeToURL:tableURL
                        atomically:YES
                          encoding:_outputStringEncoding
                             error:&error])
        {
            printf("Unable to write string table %s, %s\n", [oneTableName UTF8String], [[error localizedDescription] UTF8String]);
            exit(1);
        }
    }
}

@end
