//
//  UnitTest.m
//  UnitTest
//
//  Created by Oliver Drobnik on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UnitTest.h"
#import "DTLocalizableStringAggregator.h"
#import "DTLocalizableStringTable.h"

#import <objc/objc-class.h>


NSString *testCaseNameFromURL(NSURL *URL, BOOL withSpaces);

NSString *testCaseNameFromURL(NSURL *URL, BOOL withSpaces)
{
	NSString *fileName = [[URL path] lastPathComponent];
    NSString *name = [fileName stringByDeletingPathExtension];
    if (withSpaces)
    {
        name = [name stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    }
	
	return name;
}

@implementation UnitTest

+ (void)initialize
{
    if (self == [UnitTest class])
    {
        // get list of test case files
        NSBundle *unitTestBundle = [NSBundle bundleForClass:self];
        NSString *testcasePath = [unitTestBundle resourcePath];
        
		// make one temp folder for all cases
		NSString *timeStamp = [NSString stringWithFormat:@"%.0f", [NSDate timeIntervalSinceReferenceDate] * 1000.0];
		NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:timeStamp];
		
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:testcasePath];
        
        NSString *testFile = nil;
        while ((testFile = [enumerator nextObject]) != nil) {
            if (![testFile hasSuffix:@".txt"])
            {
                // ignore other files, e.g. custom parameters in plist
                continue;
            }
            NSString *path = [testcasePath stringByAppendingPathComponent:testFile];
            NSURL *URL = [NSURL fileURLWithPath:path];
            
            NSString *caseName = testCaseNameFromURL(URL, NO);
            NSString *selectorName = [NSString stringWithFormat:@"test_%@", caseName];
            
            void(^impBlock)(UnitTest *) = ^(UnitTest *test) {
                [test internalTestCaseWithURL:URL withTempPath:tempPath];
            };
            
            IMP myIMP = imp_implementationWithBlock((__bridge id)((__bridge void *)impBlock));
            
            SEL selector = NSSelectorFromString(selectorName);
            
            class_addMethod([self class], selector, myIMP, "v@:");
        }
    }
}


- (int)runExecutable:(NSString *)launchPath withArguments:(NSArray *)arguments
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:launchPath];
	
    [task setArguments: arguments];
    
    [task launch];
    [task waitUntilExit];
	
    return [task terminationStatus];
}


- (void)internalTestCaseWithURL:(NSURL *)URL withTempPath:(NSString *)tempPath
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// test case temp path is global temp path plus name of this test case
	tempPath = [tempPath stringByAppendingPathComponent:testCaseNameFromURL(URL, YES)];
	
    NSString *genstrings1OutPath = [tempPath stringByAppendingPathComponent:@"genstrings1"];
    [fileManager createDirectoryAtPath:genstrings1OutPath withIntermediateDirectories:YES attributes:NULL error:NULL];
    
    NSString *genstrings2OutPath = [tempPath stringByAppendingPathComponent:@"genstrings2"];
    [fileManager createDirectoryAtPath:genstrings2OutPath withIntermediateDirectories:YES attributes:NULL error:NULL];
    
    // get optional test case parameters
    NSString *parameterFile = [[[URL path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"];
    NSDictionary *testParameters = [NSDictionary dictionaryWithContentsOfFile:parameterFile];
    
    // run our code
	DTLocalizableStringAggregator *aggregator = [[DTLocalizableStringAggregator alloc] init];
	
	NSDictionary *genstrings2Parameters = [testParameters objectForKey:@"genstrings2"];
	
	if (genstrings2Parameters)
	{
		[aggregator setValuesForKeysWithDictionary:genstrings2Parameters];
	}
	
	[aggregator beginProcessingFile:URL];
	
	NSArray *tables = [aggregator aggregatedStringTables];
	NSURL *genstrings2Folder = [NSURL fileURLWithPath:genstrings2OutPath];
	
	NSDictionary *tablesParameters = [testParameters objectForKey:@"tables"];
	
	for (DTLocalizableStringTable *table in tables)
	{
		if (tablesParameters)
		{
			[table setValuesForKeysWithDictionary:tablesParameters];
		}
		[table writeToFolderAtURL:genstrings2Folder encoding:NSUTF16StringEncoding error:NULL entryWriteCallback:NULL];
	}
	
    
    // run original genstrings
    NSArray *genstringsArguments = [NSArray arrayWithObjects:
                                    [URL path],
                                    @"-o",
                                    genstrings1OutPath,
                                    nil];
    
    NSArray *customArguments = [testParameters objectForKey:@"genstrings"];
    
    if (customArguments)
    {
        genstringsArguments = [genstringsArguments arrayByAddingObjectsFromArray:customArguments];
    }
    
    
    int exitCode = [self runExecutable:@"/usr/bin/genstrings" withArguments:genstringsArguments];
    STAssertTrue(exitCode==0, @"Error running genstrings");
    
    // find output files
    NSArray *genstrings1files = [[fileManager contentsOfDirectoryAtPath:genstrings1OutPath error:NULL] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *genstrings2files = [[fileManager contentsOfDirectoryAtPath:genstrings2OutPath error:NULL] sortedArrayUsingSelector:@selector(compare:)];
    
    // check if there is any output at all
    STAssertTrue([genstrings1files count]>0, @"genstrings produced no files");
    STAssertTrue([genstrings2files count]>0, @"genstrings2 produced no files");
    
    // check if number is the same
    STAssertEquals([genstrings1files count], [genstrings2files count], @"Different number of output strings tables");
	
    for (NSString *oneFile in genstrings1files)
    {
        STAssertTrue([genstrings2files containsObject:oneFile], @"genstring2 output is missing %@", oneFile);
    }
    
    for (NSString *oneFile in genstrings2files)
    {
        STAssertTrue([genstrings1files containsObject:oneFile], @"genstring output is missing %@", oneFile);
    }
    
    if ([genstrings1files count] == [genstrings2files count]) 
	{
        NSUInteger count = [genstrings1files count];
        
        for (NSUInteger i = 0; i < count; ++i) 
		{
            NSString *genstrings1File = [genstrings1OutPath stringByAppendingPathComponent:[genstrings1files objectAtIndex:i]];
            NSString *genstrings2File = [genstrings2OutPath stringByAppendingPathComponent:[genstrings2files objectAtIndex:i]];
            
            NSString *genstrings1Contents = [NSString stringWithContentsOfFile:genstrings1File usedEncoding:NULL error:NULL];
            NSString *genstrings2Contents = [NSString stringWithContentsOfFile:genstrings2File usedEncoding:NULL error:NULL];
			
			// size check does not work because predicate editor output repeats comment for each token	
			// STAssertEquals([genstrings1Contents length], [genstrings2Contents length], @"Different file sizes on %@", genstrings1File);
			
            NSDictionary *genstrings1Stuff = [genstrings1Contents propertyListFromStringsFileFormat];
            NSDictionary *genstrings2Stuff = [genstrings2Contents propertyListFromStringsFileFormat];
            
            NSSet *genstrings1Keys = [NSSet setWithArray:[genstrings1Stuff allKeys]];
            NSSet *genstrings2Keys = [NSSet setWithArray:[genstrings2Stuff allKeys]];
            
            STAssertEqualObjects(genstrings1Keys, genstrings2Keys, @"found keys don't match");
            
            NSMutableSet *leftoverGenstrings1Keys = [genstrings1Keys mutableCopy];
            [leftoverGenstrings1Keys minusSet:genstrings2Keys];
            STAssertTrue([leftoverGenstrings1Keys count] == 0, @"genstrings2 missed these keys: %@", leftoverGenstrings1Keys);
            
            NSMutableSet *extraGenstrings2Keys = [genstrings2Keys mutableCopy];
            [extraGenstrings2Keys minusSet:genstrings1Keys];
            STAssertTrue([extraGenstrings2Keys count] == 0, @"genstrings2 found these extra keys: %@", extraGenstrings2Keys);
            
            for (NSString *genstrings2Key in genstrings2Keys) 
			{
                NSString *genstrings2Value = [genstrings2Stuff objectForKey:genstrings2Key];
                NSString *genstrings1Value = [genstrings1Stuff objectForKey:genstrings2Key];
                
                STAssertEqualObjects(genstrings2Value, genstrings1Value, @"mismatched values. genstrings found: %@, genstrings2 found: %@ (key = %@)", genstrings1Value, genstrings2Value, genstrings2Key);
            }
        }
    }
    
    // cleanup
	[[NSFileManager defaultManager] removeItemAtPath:tempPath error:NULL];
}




@end
