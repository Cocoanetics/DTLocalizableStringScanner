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

@end
