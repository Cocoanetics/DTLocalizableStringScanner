
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

@interface DTLocalizableStringAggregator ()

- (void)addEntryToTables:(DTLocalizableStringEntry *)entry;

@end

@implementation DTLocalizableStringAggregator
{
    NSArray *_fileURLs;
    NSMutableDictionary *_stringTables;
    
    NSOperationQueue *_processingQueue;
    dispatch_queue_t _tableQueue;
	
	DTLocalizableStringEntryWriteCallback _entryWriteCallback;
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
        
        _wantsPositionalParameters = YES; // default
    }
    return self;
}

- (void)dealloc 
{
	dispatch_release(_tableQueue);
}

#define KEY @"key"
#define COMMENT @"comment"
#define VALUE @"value"
#define BUNDLE @"bundle"
#define TABLE @"tableName"

- (NSDictionary *)validMacros {
    // we know the allowed formats for NSLocalizedString() macros, so we can hard-code them
    // there's no need to parse this stuff when we know what format things must be
    NSArray *prefixes = [NSArray arrayWithObjects:@"NSLocalizedString", @"CFCopyLocalizedString", _customMacroPrefix, nil];
    NSDictionary *suffixes = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSArray arrayWithObjects:KEY, COMMENT, nil], @"",
                              [NSArray arrayWithObjects:KEY, TABLE, COMMENT, nil], @"FromTable",
                              [NSArray arrayWithObjects:KEY, TABLE, BUNDLE, COMMENT, nil], @"FromTableInBundle",
                              [NSArray arrayWithObjects:KEY, TABLE, BUNDLE, VALUE, COMMENT, nil], @"WithDefaultValue",
                              nil];
    
    NSMutableDictionary *validMacros = [NSMutableDictionary dictionary];
    for (NSString *prefix in prefixes) {
        for (NSString *suffix in suffixes) {
            NSString *macroName = [prefix stringByAppendingString:suffix];
            NSArray *parameters = [suffixes objectForKey:suffix];
            
            [validMacros setObject:parameters forKey:macroName];
        }
    }
    
    return validMacros;
}

- (void)processFiles
{
    NSDictionary *validMacros = [self validMacros];
    
    dispatch_group_t tableGroup = dispatch_group_create();
    // create one block for each file
    for (NSURL *oneFile in _fileURLs)
    {
        DTLocalizableStringScanner *scanner = [[DTLocalizableStringScanner alloc] initWithContentsOfURL:oneFile validMacros:validMacros];
        [scanner setEntryFoundCallback:^(DTLocalizableStringEntry *entry) {
            dispatch_group_async(tableGroup, _tableQueue, ^{
                [self addEntryToTables:entry];
            });
        }];
		
        [_processingQueue addOperation:scanner];
    }
    
    // wait until all the files and entries have been processed before writing the tables
    [_processingQueue waitUntilAllOperationsAreFinished];
    dispatch_group_wait(tableGroup, DISPATCH_TIME_FOREVER);
    dispatch_release(tableGroup);
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
		if (![oneTable writeToFolderAtURL:URL 
								 encoding:encoding 
									error:error 
					   entryWriteCallback:_entryWriteCallback])
		{
			return NO;
		}
	}
	
	return YES;
}

#pragma mark Properties

@synthesize entryWriteCallback=_entryWriteCallback;

@end
