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

void showUsage(void);

int main (int argc, const char *argv[])
{
    @autoreleasepool 
    {
        BOOL noPositionalParameters = NO;
        NSMutableSet *tablesToSkip = [NSMutableSet set];
        
        
        // analyze options
        BOOL endOfOptions = NO;
        BOOL optionsInvalid = NO;
        NSUInteger i = 0;
        
        while (!endOfOptions)
        {
            i++;
            
            if (i>=argc)
            {
                break;
            }
            
            if (argv[i][0]!='-')
            {
                // not a parameter
                endOfOptions = YES;
                continue;
            }
            
            if (!strcmp("-noPositionalParameters", argv[i]))
            {
                noPositionalParameters = YES;
            }
            else if (!strcmp("-skipTable", argv[i]))
            {
                i++;
                
                if (i>=argc)
                {
                    // table name is missing
                    optionsInvalid = YES;
                    break;
                }
                
                NSString *tableName = [NSString stringWithUTF8String:argv[i]];
                [tablesToSkip addObject:tableName];
            }
        }
        
        // assemble absolute file URLs for the passed files
        NSMutableArray *files = [NSMutableArray array];
        for (; i<argc; i++)
        {
            NSString *fileName = [NSString stringWithUTF8String:argv[i]];
            NSURL *url = [NSURL fileURLWithPath:fileName];
            
            [files addObject:url];
        }
        
        if (optionsInvalid || ![files count])
        {
            showUsage();
            exit(1);
        }
            

        
        // process all files
        DTLocalizableStringAggregator *aggregator = [[DTLocalizableStringAggregator alloc] initWithFileURLs:files];
        aggregator.noPositionalParameters = noPositionalParameters;
        
        if ([tablesToSkip count])
        {
            // do not set an empty set to improve performance
            aggregator.tablesToSkip = tablesToSkip;
        }
        
        [aggregator processFiles];
    }
    return 0;
}


void showUsage(void)
{
    printf("Usage: genstrings2 [OPTION] file1.[mc] ... filen.[mc]\n\n");
    printf("    Options\n");
 //   printf("    -j                       sets the input language to Java.\n");
 //   printf("    -a                       append output to the old strings files.\n");
 //   printf("    -s substring             substitute 'substring' for NSLocalizedString.\n");
    printf("    -skipTable tablename     skip over the file for 'tablename'.\n");
    printf("    -noPositionalParameters  turns off positional parameter support.\n");
 //   printf("    -u                       allow unicode characters.\n");
 //   printf("    -macRoman                read files as MacRoman not UTF-8.\n");
 //   printf("    -q                       turns off multiple key/value pairs warning.\n");
 //   printf("    -bigEndian               output generated with big endian byte order.\n");
 //   printf("    -littleEndian            output generated with little endian byte order.\n");
    printf("    -o dir                   place output files in 'dir'.\n\n");
    printf("    Please see the genstrings2(1) man page for full documentation\n");
}


