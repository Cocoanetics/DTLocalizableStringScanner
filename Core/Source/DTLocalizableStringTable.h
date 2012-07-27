//
//  DTLocalizableStringTable.h
//  genstrings2
//
//  Created by Oliver Drobnik on 1/12/12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTLocalizableStringEntry;

typedef void(^DTLocalizableStringEntryWriteCallback)(DTLocalizableStringEntry *);

@interface DTLocalizableStringTable : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, assign) BOOL shouldDecodeUnicodeSequences;

- (id)initWithName:(NSString *)name;

- (void)addEntry:(DTLocalizableStringEntry *)entry;

- (NSString*)writeAsStringEncoding:(NSStringEncoding)encoding error:(NSError **)error entryWriteCallback:(DTLocalizableStringEntryWriteCallback)entryWriteCallback;
- (BOOL)writeToFolderAtURL:(NSURL *)url encoding:(NSStringEncoding)encoding error:(NSError **)error entryWriteCallback:(DTLocalizableStringEntryWriteCallback)entryWriteCallback;

@end
