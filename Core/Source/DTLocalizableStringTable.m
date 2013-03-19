//
//  DTLocalizableStringTable.m
//  genstrings2
//
//  Created by Oliver Drobnik on 1/12/12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import "DTLocalizableStringTable.h"

#import "DTLocalizableStringEntry.h"
#import "NSString+DTLocalizableStringScanner.h"

@implementation DTLocalizableStringTable
{
	NSString *_name;
	NSMutableArray *_entries;
	NSMutableDictionary *_entryIndexByKey;
	
	DTLocalizableStringEntryWriteCallback _entryWriteCallback;
}

- (id)initWithName:(NSString *)name
{
	self = [super init];
	if (self)
	{
		_name = [name copy];
	}
	
	return self;
}

- (void)addEntry:(DTLocalizableStringEntry *)entry
{
	NSAssert([entry.tableName isEqualToString:_name], @"Entry does not belong in this table: %@ != %@", entry.tableName, _name);
	
	NSString *key = entry.rawKey;
	
	NSParameterAssert(key);
	
	if (!_entries)
	{
		_entries = [[NSMutableArray alloc] init];
	}
	
	if (!_entryIndexByKey)
	{
		_entryIndexByKey = [[NSMutableDictionary alloc] init];
	}
	
	// check if we already have such an entry
	DTLocalizableStringEntry *existingEntry = [_entryIndexByKey objectForKey:key];
	
	if (existingEntry)
	{
		if (![existingEntry.rawValue isEqualToString:entry.rawValue])
		{
			printf("Key \"%s\" used with multiple values. Value \"%s\" kept. Value \"%s\" ignored.\n",
				   [key UTF8String], [existingEntry.rawValue UTF8String], [entry.rawValue UTF8String]);
		}
		
		for (NSString *oneComment in [entry sortedComments])
		{
			[existingEntry addComment:oneComment];
		}
		
		return;
	}
	
	// add entry to table and key index
	[_entries addObject:entry];
	[_entryIndexByKey setObject:entry forKey:entry.rawKey];
}

- (NSString*)stringRepresentationWithEncoding:(NSStringEncoding)encoding error:(NSError **)error entryWriteCallback:(DTLocalizableStringEntryWriteCallback)entryWriteCallback
{
    NSArray *sortedEntries = [_entries sortedArrayUsingSelector:@selector(compare:)];
	
	NSMutableString *tmpString = [NSMutableString string];
	
	for (DTLocalizableStringEntry *entry in sortedEntries)
	{
		NSString *key = [entry rawKey];
		NSString *value = [entry rawValue];
        
        if (entryWriteCallback)
        {
            entryWriteCallback(entry);
        }
        
        // multi-line comments are indented
        NSString *comment = [[entry sortedComments] componentsJoinedByString:@"\n   "];
        if (!comment)
        {
            comment = @"No comment provided by engineer.";
        }
        
        if (_shouldDecodeUnicodeSequences) 
		{
			// strip the quotes
			if ([value hasPrefix:@"\""] && [value hasPrefix:@"\""])
			{
				value = [value substringWithRange:NSMakeRange(1, [value length]-2)];
			}
			
			// value is what we scanned from file, so we first need to decode
			value = [value stringByReplacingSlashEscapes];
			
			// decode the unicode sequences
            value = [value stringByDecodingUnicodeSequences];
			
			// re-add the slash escapes
			value = [value stringByAddingSlashEscapes];
			
			// re-add quotes
			value = [NSString stringWithFormat:@"\"%@\"", value];
        }
        
        // output comment
        [tmpString appendFormat:@"/* %@ */\n", comment];
        
        // output line
        [tmpString appendFormat:@"%@ = %@;\n", key, value];
        
        [tmpString appendString:@"\n"];
	}
    
    return [NSString stringWithString:tmpString];
}

- (BOOL)writeToFolderAtURL:(NSURL *)url encoding:(NSStringEncoding)encoding error:(NSError **)error  entryWriteCallback:(DTLocalizableStringEntryWriteCallback)entryWriteCallback;
{
	NSString *fileName = [_name stringByAppendingPathExtension:@"strings"];
	NSString *tablePath = [[url path] stringByAppendingPathComponent:fileName];
	NSURL *tableURL = [NSURL fileURLWithPath:tablePath];
	
	if (!tableURL)
	{
		// this must be junk
		return NO;
	}
	
    NSString *tmpString = [self stringRepresentationWithEncoding:encoding error:error entryWriteCallback:entryWriteCallback];
	
	return [tmpString writeToURL:tableURL
					  atomically:YES
						encoding:encoding
						   error:error];
}

#pragma mark Properties

@synthesize name = _name;
@synthesize entries = _entries;
@synthesize shouldDecodeUnicodeSequences = _shouldDecodeUnicodeSequences;

@end
