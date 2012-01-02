//
//  main.m
//  genstrings2
//
//  Created by Oliver Drobnik on 29.12.11.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTLocalizableStringScanner.h"
#import "DTLocalizableStringAggregator.h"

int main (int argc, const char * argv[])
{
    @autoreleasepool 
    {
        // assemble absolute file URLs for the passed files
        NSMutableArray *files = [NSMutableArray array];
        for (NSInteger i=1; i<argc; i++)
        {
            NSString *fileName = [NSString stringWithUTF8String:argv[i]];
            NSURL *url = [NSURL fileURLWithPath:fileName];
            
            [files addObject:url];
        }
 
        // process all files
        DTLocalizableStringAggregator *aggregator = [[DTLocalizableStringAggregator alloc] initWithFileURLs:files];
        [aggregator processFiles];
    }
    return 0;
}

