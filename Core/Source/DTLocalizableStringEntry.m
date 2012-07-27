//
//  DTLocalizableStringEntry.m
//  genstrings2
//
//  Created by Oliver Drobnik on 10.01.12.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import "DTLocalizableStringEntry.h"
#import "NSString+DTLocalizableStringScanner.h"

@implementation DTLocalizableStringEntry
{
	NSMutableSet *_comments;
	
	NSArray *_sortedCommentsCache;
    NSString *_cleanedKey;
}

@synthesize rawKey=_rawKey;
@synthesize rawValue=_rawValue;
@synthesize tableName=_tableName;
@synthesize bundle=_bundle;

- (NSString *)description
{
	NSMutableString *tmpString = [NSMutableString stringWithFormat:@"<%@ key='%@'", NSStringFromClass([self class]), self.rawKey];
	
	if (_rawValue)
	{
		[tmpString appendFormat:@" value='%@'", _rawValue];
	}
	
	if ([_tableName length])
	{
		[tmpString appendFormat:@" table='%@'", _tableName];
	}
	
	[tmpString appendString:@">"];
	
	return tmpString;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone
{
	DTLocalizableStringEntry *newEntry = [[DTLocalizableStringEntry allocWithZone:zone] init];
	newEntry.rawKey = _rawKey;
	newEntry.rawValue = _rawValue;
	newEntry.tableName = _tableName;
	newEntry.bundle = _bundle;
	
	for (NSString *oneComment in _comments)
	{
		[newEntry addComment:oneComment];
	}
	
	return newEntry;
}

- (NSComparisonResult)compare:(DTLocalizableStringEntry *)otherEntry
{
    return [self.cleanedKey localizedStandardCompare:otherEntry.cleanedKey];
}

- (NSString *)_stringByRecognizingNil:(NSString *)string 
{
    NSString *tmp = [string lowercaseString];
    if ([tmp isEqualToString:@"nil"] || [tmp isEqualToString:@"null"] || [tmp isEqualToString:@"0"]) 
    {
        string = nil;
    }
    return string;
}

#pragma mark Properties

- (void)setTableName:(NSString *)tableName
{
    tableName = [tableName stringByReplacingSlashEscapes];
    tableName = [self _stringByRecognizingNil:tableName];
	
	// remove the quotes
	tableName = [tableName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
    
	// keep "Localizable" if the tableName is nil or @"";
	if ([tableName length])
	{
		_tableName = [tableName copy];
	}
}

- (void)setComment:(NSString *)comment; // for KVC
{
	_comments = nil;
	[self addComment:comment];
}

- (void)addComment:(NSString *)comment
{
    comment = [self _stringByRecognizingNil:comment];

	// remove the quotes
	comment = [comment stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
	
	if (![comment length])
	{
		return;
	}

	if (!_comments)
	{
		_comments = [[NSMutableSet alloc] init];
	}
	
	if (![_comments containsObject:comment])
	{
		[_comments addObject:[comment copy]];
		
		// invalidates sorted cache
		_sortedCommentsCache = nil;
	}
}

- (NSArray *)sortedComments
{
	if (!_comments)
	{
		return nil;
	}
	
	if (_sortedCommentsCache)
	{
		return _sortedCommentsCache;
	}
    
    _sortedCommentsCache = [[_comments allObjects] sortedArrayUsingSelector:@selector(compare:)];
	
	return _sortedCommentsCache;
}

- (void) setRawKey:(NSString *)rawKey {
    if (rawKey != _rawKey) {
        _rawKey = rawKey;
        _cleanedKey = nil;
    }
}

- (NSString *)cleanedKey 
{
    if (_cleanedKey == nil && _rawKey != nil) {
        _cleanedKey = [_rawKey stringByReplacingSlashEscapes];
    }
    return _cleanedKey;
}

- (NSString *)cleanedValue 
{
    return [[self rawValue] stringByReplacingSlashEscapes];
}

@end
