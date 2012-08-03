
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
	NSDictionary *_validMacros;
	NSMutableDictionary *_stringTables;
	
	NSOperationQueue *_processingQueue;
	dispatch_queue_t _tableQueue;
	dispatch_group_t _tableGroup;
	
	DTLocalizableStringEntryWriteCallback _entryWriteCallback;
}

#pragma mark properties

@synthesize wantsPositionalParameters = _wantsPositionalParameters;
@synthesize inputEncoding = _inputEncoding;
@synthesize tablesToSkip = _tablesToSkip;
@synthesize customMacroPrefix = _customMacroPrefix;
@synthesize defaultTableName = _defaultTableName;

- (id)init
{
	self = [super init];
	if (self)
	{
		_tableQueue = dispatch_queue_create("DTLocalizableStringAggregator", 0);
		_tableGroup = dispatch_group_create();
		
		_processingQueue = [[NSOperationQueue alloc] init];
		[_processingQueue setMaxConcurrentOperationCount:10];
		
		_wantsPositionalParameters = YES; // default
		_inputEncoding = NSUTF8StringEncoding; // default
	}
	return self;
}

- (void)dealloc
{
	dispatch_release(_tableQueue);
	dispatch_release(_tableGroup);
}

- (void)setCustomMacroPrefix:(NSString *)customMacroPrefix
{
	if (customMacroPrefix != _customMacroPrefix)
	{
		_customMacroPrefix = customMacroPrefix;
		_validMacros = nil;
	}
}

#define KEY @"rawKey"
#define COMMENT @"comment"
#define VALUE @"rawValue"
#define BUNDLE @"bundle"
#define TABLE @"tableName"

- (NSDictionary *)validMacros
{
	if (!_validMacros)
	{
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
		for (NSString *prefix in prefixes)
		{
			for (NSString *suffix in suffixes)
			{
				NSString *macroName = [prefix stringByAppendingString:suffix];
				NSArray *parameters = [suffixes objectForKey:suffix];
				
				[validMacros setObject:parameters forKey:macroName];
			}
		}
		
		_validMacros = validMacros;
	}
	
	return _validMacros;
}

#define QUOTE @"\""

- (void)beginProcessingFile:(NSURL *)fileURL
{
	NSDictionary *validMacros = [self validMacros];
	
	DTLocalizableStringScanner *scanner = [[DTLocalizableStringScanner alloc] initWithContentsOfURL:fileURL encoding:_inputEncoding validMacros:validMacros];
	
	[scanner setEntryFoundCallback:^(DTLocalizableStringEntry *entry)
    {
		 NSString *key = [entry rawKey];
		 NSString *value = [entry rawValue];
		 BOOL shouldBeAdded = ([key hasPrefix:QUOTE] && [key hasSuffix:QUOTE]);
		 
		 if (value)
		 {
			 shouldBeAdded &= ([value hasPrefix:QUOTE] && [value hasSuffix:QUOTE]);
		 }
		 
		 if (shouldBeAdded)
		 {
			 dispatch_group_async(_tableGroup, _tableQueue, ^{
				 [self addEntryToTables:entry];
			 });
		 }
		 else
		 {
			 NSLog(@"skipping: %@", entry);
		 }
    }];
	
	[_processingQueue addOperation:scanner];
}

- (void)addEntryToTables:(DTLocalizableStringEntry *)entry
{
	NSAssert(dispatch_get_current_queue() == _tableQueue, @"method called from invalid queue");
	if (!_stringTables)
	{
		_stringTables = [NSMutableDictionary dictionary];
	}
	
	// use default table name is no name set
	if (![entry.tableName length])
	{
		entry.tableName = _defaultTableName ? _defaultTableName : @"Localizable";
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
		
		if (entry.rawValue)
		{
			// ...WithDefaultValue
			if (_wantsPositionalParameters)
			{
				entry.rawValue = [entry.rawValue stringByNumberingFormatPlaceholders];
			}
			
			[table addEntry:entry];
		}
		else
		{
			// all other options use the key and variations thereof
			
			// support for predicate token splitting
			NSArray *keyVariants = [entry.rawKey variantsFromPredicateVariations];
			
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
				splitEntry.rawKey = oneVariant;
				splitEntry.rawValue = value;
				
				// add token to this table
				[table addEntry:splitEntry];
			}
		}
	}
}

- (NSArray *)aggregatedStringTables
{
	// wait for both of these things to finish
	[_processingQueue waitUntilAllOperationsAreFinished];
	dispatch_group_wait(_tableGroup, DISPATCH_TIME_FOREVER);
	
	return [_stringTables allValues];
}

@end
