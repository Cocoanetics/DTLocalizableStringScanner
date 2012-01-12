//
//  DTLocalizableStringTable.h
//  genstrings2
//
//  Created by Oliver Drobnik on 1/12/12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTLocalizableStringEntry.h"

@interface DTLocalizableStringTable : NSObject

@property (nonatomic, readonly) NSString *name;

- (id)initWithName:(NSString *)name;

- (void)addEntry:(DTLocalizableStringEntry *)entry;

- (BOOL)writeToFolderAtURL:(NSURL *)url encoding:(NSStringEncoding)encoding error:(NSError **)error entryWriteCallback:(DTLocalizableStringEntryWriteCallback)entryWriteCallback;

@end
