//
//  DTLocalizableStringEntry.m
//  genstrings2
//
//  Created by Oliver Drobnik on 10.01.12.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import "DTLocalizableStringEntry.h"

@implementation DTLocalizableStringEntry
{
	NSMutableSet *_comments;
	
	NSArray *_sortedCommentsCache;
}

@synthesize key=_key;
@synthesize value=_value;
@synthesize tableName=_tableName;
@synthesize bundle=_bundle;

- (id)init {
    self = [super init];
    if (self) 
	{
		_tableName = @"Localizable";
    }
    return self;
}

- (NSString *)description
{
	NSMutableString *tmpString = [NSMutableString stringWithFormat:@"<%@ key='%@'", NSStringFromClass([self class]), self.key];
	
	if (_value)
	{
		[tmpString appendFormat:@" value='%@'", _value];
	}
	
	if ([_tableName length] && ![_tableName isEqualToString:@"Localizable"])
	{
		[tmpString appendFormat:@" table='%@'", _tableName];
	}
	
	[tmpString appendString:@">"];
	
	return tmpString;
}

#pragma NSCopying
- (id)copyWithZone:(NSZone *)zone
{
	DTLocalizableStringEntry *newEntry = [[DTLocalizableStringEntry allocWithZone:zone] init];
	newEntry.key = _key;
	newEntry.value = _value;
	newEntry.tableName = _tableName;
	newEntry.bundle = _bundle;
	
	for (NSString *oneComment in _comments)
	{
		[newEntry addComment:oneComment];
	}
	
	return newEntry;
}

#pragma mark Properties
- (void)setTableName:(NSString *)tableName
{
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
	
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES];
	_sortedCommentsCache = [_comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
	
	return _sortedCommentsCache;
}

@end
