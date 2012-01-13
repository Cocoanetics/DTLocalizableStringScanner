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
#import "DTLocalizableStringEntry.h"

void showUsage(void);

int main (int argc, const char *argv[])
{
    @autoreleasepool 
    {
		// default output folder = current working dir
        NSURL *outputFolderURL = nil;
        
        // default output encoding
        NSStringEncoding outputStringEncoding = NSUTF16StringEncoding;
        
        BOOL wantsPositionalParameters = YES;
		BOOL wantsMultipleCommentWarning = YES;
        NSMutableSet *tablesToSkip = [NSMutableSet set];
        NSString *customMacroPrefix = nil;
        
        // analyze options
        BOOL optionsInvalid = NO;
        NSUInteger i = 1;
        NSMutableArray *files = [NSMutableArray array];
        
        while (i<argc)
        {
            if (argv[i][0]!='-')
            {
                // not a parameter, treat as file name
                NSString *fileName = [NSString stringWithUTF8String:argv[i]];
                
                // standardize path
                fileName = [fileName stringByStandardizingPath];
                
                NSURL *url = [NSURL fileURLWithPath:fileName];
                
                if (!url)
                {
                    optionsInvalid = YES;
                    break;
                }
                
                [files addObject:url];
            }
            else if (!strcmp("-noPositionalParameters", argv[i]))
            {
                // do not add positions to parameters
                wantsPositionalParameters = NO;
            }
            else if (!strcmp("-o", argv[i]))
            {
                // output folder name
                i++;
                
                if (i>=argc)
                {
                    // output folder name is missing
                    optionsInvalid = YES;
                    break;
                }
                
                // output folder
                NSString *fileName = [NSString stringWithUTF8String:argv[i]];
                
                // standardize path
                fileName = [fileName stringByStandardizingPath];
                
                // check if output folder exists
                if (![[NSFileManager defaultManager] isWritableFileAtPath:fileName])
                {
                    printf("Unable to write to %s\n", [fileName UTF8String]);
                    exit(1);
                }
                
                outputFolderURL = [NSURL fileURLWithPath:fileName];
            }
            else if (!strcmp("-s", argv[i]))
            {
                // custom macro prefix
                i++;
                
                if (i>=argc)
                {
                    // prefix is missing
                    optionsInvalid = YES;
                    break;
                }
                
                customMacroPrefix = [NSString stringWithUTF8String:argv[i]];
            }
			else if (!strcmp("-q", argv[i]))
			{
				// do not warn if multiple different comments are attached to a token
				wantsMultipleCommentWarning = NO;
			}
            else if (!strcmp("-skipTable", argv[i]))
            {
                // tables to be ignored
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
            else if (!strcmp("-littleEndian", argv[i]))
            {
                outputStringEncoding = NSUTF16LittleEndianStringEncoding;
            }
            else if (!strcmp("-bigEndian", argv[i]))
            {
                outputStringEncoding = NSUTF16BigEndianStringEncoding;
            }
            
            i++;
        }
        
        // something is wrong
        if (optionsInvalid || ![files count])
        {
            showUsage();
            exit(1);
        }
        
        // create the aggregator
        DTLocalizableStringAggregator *aggregator = [[DTLocalizableStringAggregator alloc] initWithFileURLs:files];
        
        // set the parameters
        aggregator.wantsPositionalParameters = wantsPositionalParameters;
        aggregator.customMacroPrefix = customMacroPrefix;
        
        if ([tablesToSkip count])
        {
            // do not set an empty set to improve performance
            aggregator.tablesToSkip = tablesToSkip;
        }
        
		if (wantsMultipleCommentWarning)
		{
			aggregator.entryWriteCallback = ^(DTLocalizableStringEntry *entry) 
			{
				NSArray *comments = [entry sortedComments];
				
				if ([comments count]>1)
				{
					NSString *tmpString = [comments componentsJoinedByString:@"\" & \""];
					printf("Warning: Key \"%s\" used with multiple comments \"%s\"\n", [entry.rawKey UTF8String], [tmpString UTF8String]);
				}	
			};
		}
		
        // go, go, go!
        [aggregator processFiles];
		
		// set output dir to current working dir if not set
		if (!outputFolderURL)
		{
			NSString *cwd = [[NSFileManager defaultManager] currentDirectoryPath];
			outputFolderURL = [NSURL fileURLWithPath:cwd];
		}
		
		// output the tables
		NSError *error = nil;
		if (![aggregator writeStringTablesToFolderAtURL:outputFolderURL encoding:outputStringEncoding error:&error])
		{
			printf("%s\n", [[error localizedDescription] UTF8String]);
			exit(1); // exit due to error
		}
    }
    
    return 0;
}


void showUsage(void)
{
    printf("Usage: genstrings2 [OPTIONS] file...\n\n");
    printf("    Options\n");
    //   printf("    -j                       sets the input language to Java.\n");
    //   printf("    -a                       append output to the old strings files.\n");
    printf("    -s substring             substitute 'substring' for NSLocalizedString.\n");
    printf("    -skipTable tablename     skip over the file for 'tablename'.\n");
    printf("    -noPositionalParameters  turns off positional parameter support.\n");
    //   printf("    -u                       allow unicode characters.\n");
    //   printf("    -macRoman                read files as MacRoman not UTF-8.\n");
    printf("    -q                       turns off multiple key/value pairs warning.\n");
    printf("    -bigEndian               output generated with big endian byte order.\n");
    printf("    -littleEndian            output generated with little endian byte order.\n");
    printf("    -o dir                   place output files in 'dir'.\n\n");
    printf("    Please see the genstrings2(1) man page for full documentation\n");
}


