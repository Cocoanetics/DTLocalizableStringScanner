//
//  DTLocalizableStringAggregator.m
//  genstrings2
//
//  Created by Oliver Drobnik on 02.01.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import "DTLocalizableStringAggregator.h"
#import "DTLocalizableStringScanner.h"

@implementation DTLocalizableStringAggregator
{
    NSArray *_fileURLs;
    NSMutableDictionary *_stringTables;
    NSURL *_outputFolderURL;
}

- (id)initWithFileURLs:(NSArray *)fileURLs
{
    self = [super init];
    if (self)
    {
        _fileURLs = fileURLs;
    }
    return self;
}

- (void)setOutputFolderURL:(NSURL *)outputFolderURL
{
    _outputFolderURL = outputFolderURL;
}

- (void)processFiles
{
    // set output dir to current working dir if not set
    if (!_outputFolderURL)
    {
        NSString *cwd = [[NSFileManager defaultManager] currentDirectoryPath];
        _outputFolderURL = [NSURL fileURLWithPath:cwd];
    }
    
    // create one dispatch group
    dispatch_group_t group = dispatch_group_create();
    
    // create one block for each file
    for (NSURL *oneFile in _fileURLs)
    {
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            DTLocalizableStringScanner *scanner = [[DTLocalizableStringScanner alloc] initWithContentsOfURL:oneFile];
            scanner.delegate = self;
            [scanner scanFile];
        });
    }
    
    // wait for all blocks in group to finish
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    NSArray *tableNames = [_stringTables allKeys];
    
    for (NSString *oneTableName in tableNames)
    {
        NSString *fileName = [oneTableName stringByAppendingPathExtension:@"strings"];
        NSURL *tableURL = [NSURL URLWithString:fileName relativeToURL:_outputFolderURL];
        
        NSArray *tokens = [_stringTables objectForKey:oneTableName];
        
        NSMutableString *tmpString = [NSMutableString string];
        
        for (NSDictionary *oneToken in tokens)
        {
            NSString *comment = [oneToken objectForKey:@"comment"];
            NSString *key = [oneToken objectForKey:@"key"];
            
            [tmpString appendFormat:@"/* %@ */\n\"%@\" = \"%@\";\n\n", comment, key, key];
        }
        
        NSError *error = nil;
        if (![tmpString writeToURL:tableURL
                   atomically:YES
                     encoding:NSUTF16StringEncoding
                        error:&error])
        {
            printf("Unable to write string table %s, %s\n", [oneTableName UTF8String], [[error localizedDescription] UTF8String]);
            exit(1);
        }
        
        NSLog(@"%@", [tableURL path]);
    }
}

- (void)addTokenToTables:(NSDictionary *)token
{
    // needs to be synchronized because it might be called from background threads
    @synchronized(self)
    {
        if (!_stringTables)
        {
            _stringTables = [NSMutableDictionary dictionary];
        }
        
        NSString *tableName = [token objectForKey:@"tbl"];
        if (!tableName)
        {
            tableName = @"Localizable";
        }
        
        // find the string table for this token, or create it
        NSMutableArray *table = [_stringTables objectForKey:tableName];
        if (!table)
        {
            // need to create it
            table = [NSMutableArray array];
            [_stringTables setObject:table forKey:tableName];
        }
        
        // add token to this table
        [table addObject:token];
    }
}

#pragma mark DTLocalizableStringScannerDelegate

- (void)localizableStringScanner:(DTLocalizableStringScanner *)scanner didFindToken:(NSDictionary *)token
{
    [self addTokenToTables:token];
}

@end
