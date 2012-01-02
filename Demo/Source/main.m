//
//  main.m
//  genstrings2
//
//  Created by Oliver Drobnik on 29.12.11.
//  Copyright (c) 2011 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTLocalizableStringScanner.h"

int main (int argc, const char * argv[])
{
    @autoreleasepool 
    {
        NSMutableArray *files = [NSMutableArray array];
        
        for (NSInteger i=1; i<argc; i++)
        {
            NSString *fileName = [NSString stringWithUTF8String:argv[i]];
            [files addObject:fileName];
        }

        NSLog(@"Start Parsing");
        
        for (NSString *oneFile in files)
        {
            NSURL *url = [NSURL fileURLWithPath:oneFile];
            DTLocalizableStringScanner *parser = [[DTLocalizableStringScanner alloc] initWithContentsOfURL:url];

            [parser parse];
            
            NSLog(@"%@ = %@", [oneFile lastPathComponent], [parser scanResults]);
        }
        
        NSLog(@"Parsing Finished");
        
        
    }
    return 0;
}

