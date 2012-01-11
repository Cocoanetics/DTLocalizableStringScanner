//
//  DTLocalizableStringEntry.m
//  genstrings2
//
//  Created by Oliver Drobnik on 10.01.12.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import "DTLocalizableStringEntry.h"

@implementation DTLocalizableStringEntry

@synthesize key=_key;
@synthesize value=_value;
@synthesize tableName=_tableName;
@synthesize bundle=_bundle;
@synthesize comment=_comment;

- (id)init {
    self = [super init];
    if (self) {
        _tableName = @"Localizable";
        _comment = @"No comment provided by engineer";
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
	
	if ([_comment length] && ![_comment isEqualToString:@"No comment provided by engineer"])
	{
		[tmpString appendFormat:@" comment='%@'", _comment];
	}

	if (![_tableName isEqualToString:@"Localizable"])
	{
		[tmpString appendFormat:@" table='%@'", _tableName];
	}
	
	[tmpString appendString:@">"];
	
	return tmpString;
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

- (void)setComment:(NSString *)comment
{
	// keep default comment if the parameter is nil or @"";
	if ([comment length])
	{
		_comment = [comment copy];
	}
}

@end
