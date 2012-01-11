//
//  DTLocalizableStringEntry.h
//  genstrings2
//
//  Created by Oliver Drobnik on 10.01.12.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTLocalizableStringEntry : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) NSString *tableName;
@property (nonatomic, copy) NSString *bundle;
@property (nonatomic, copy) NSString *comment;

// used for output sorting
- (NSComparisonResult)compare:(DTLocalizableStringEntry *)otherEntry;

@end
