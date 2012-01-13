//
//  UnitTest.m
//  UnitTest
//
//  Created by Oliver Drobnik on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UnitTest.h"
#import "DTLocalizableStringAggregator.h"

#import </usr/include/objc/objc-class.h>


NSString *testCaseNameFromURL(NSURL *URL)
{
	NSString *fileName = [[URL path] lastPathComponent];
	NSString *name = [[fileName stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
	
	return name;
}


static UnitTest *_sharedInstance = nil;

@implementation UnitTest
{
	NSArray *_testcaseFileURLs;
}


//+ (NSArray *)testInvocations
//{
//	NSMutableArray *tmpArray = [NSMutableArray array];
//	
//	// get list of test case files
//	NSString *projectPath = [[NSFileManager defaultManager] currentDirectoryPath];
//	NSString *testcasePath = [projectPath stringByAppendingPathComponent:@"Test/Resources"];
//	
//	NSError *error = nil;
//	NSArray *testcases = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:testcasePath error:&error];
//	
//	for (NSString *oneFile in testcases)
//	{
//		NSString *path = [testcasePath stringByAppendingPathComponent:oneFile];
//		NSURL *URL = [NSURL fileURLWithPath:path];
//		
//		NSString *caseName = [testCaseNameFromURL(URL) stringByReplacingOccurrencesOfString:@" " withString:@"_"];
//		NSString *selectorName = [NSString stringWithFormat:@"test_%@", caseName];
//		SEL selector = NSSelectorFromString(selectorName);
//		
//		NSMethodSignature *mySignature = [UnitTest instanceMethodSignatureForSelector:@selector(setUp)];
//		NSInvocation *myInvocation = [NSInvocation invocationWithMethodSignature:mySignature];
//	//	[myInvocation setArgument:&URL atIndex:2];
//		[myInvocation setSelector:selector];
//		[myInvocation retainArguments];
//		
//		[tmpArray addObject:myInvocation];
//	}
//	
//	return tmpArray;
//}

+ (void)initialize
{
	// get list of test case files
	NSString *projectPath = [[NSFileManager defaultManager] currentDirectoryPath];
	NSString *testcasePath = [projectPath stringByAppendingPathComponent:@"Test/Resources"];
	
	NSError *error = nil;
	NSArray *testcases = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:testcasePath error:&error];
	
	for (NSString *oneFile in testcases)
	{
		NSString *path = [testcasePath stringByAppendingPathComponent:oneFile];
		NSURL *URL = [NSURL fileURLWithPath:path];

		NSString *caseName = [testCaseNameFromURL(URL) stringByReplacingOccurrencesOfString:@" " withString:@"_"];
		NSString *selectorName = [NSString stringWithFormat:@"test_%@", caseName];

		IMP myIMP = imp_implementationWithBlock((void *)objc_unretainedPointer(^{ [_sharedInstance internalTestCaseWithURL:URL]; }));
		
		SEL selector = NSSelectorFromString(selectorName);
		
		class_addMethod([self class], selector, myIMP, "v@:");
	}
}

- (void)setUp
{
	_sharedInstance = self;
	
    [super setUp];
    
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}




-(void) runScriptWithArguments:(NSArray *)arguments
{
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
	
//    NSArray *arguments;
//    NSString* newpath = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] privateFrameworksPath], scriptName];
//    NSLog(@"shell script path: %@",newpath);
//    arguments = [NSArray arrayWithObjects:scriptName, nil];
    [task setArguments: arguments];
	
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
	
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
	
    [task launch];
	
    NSData *data;
    data = [file readDataToEndOfFile];
	
    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"script returned:\n%@", string);    
}

																			   
- (void)internalTestCaseWithURL:(NSURL *)URL
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	{
		NSString *timeStamp = [NSString stringWithFormat:@"%.0f", [NSDate timeIntervalSinceReferenceDate] * 1000.0];
		
		NSString *tempPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:timeStamp] stringByAppendingPathComponent:testCaseNameFromURL(URL)];
		
		NSString *genstrings1OutPath = [tempPath stringByAppendingPathComponent:@"genstrings1"];
		[fileManager createDirectoryAtPath:genstrings1OutPath withIntermediateDirectories:YES attributes:NULL error:NULL];
		
		NSString *genstrings2OutPath = [tempPath stringByAppendingPathComponent:@"genstrings2"];
		[fileManager createDirectoryAtPath:genstrings2OutPath withIntermediateDirectories:YES attributes:NULL error:NULL];
							  

		// run our code
		DTLocalizableStringAggregator *aggregator = [[DTLocalizableStringAggregator alloc] initWithFileURLs:[NSArray arrayWithObject:URL]];
		[aggregator processFiles];
		[aggregator writeStringTablesToFolderAtURL:[NSURL fileURLWithPath:genstrings2OutPath] encoding:NSUTF16StringEncoding error:NULL];
		
		// run original genstrings
		NSString *command = [NSString stringWithFormat:@"genstrings \"%@\" -o \"%@\"",  [URL path], genstrings1OutPath];
		int exitCode = system([command UTF8String]);
		STAssertTrue(exitCode==0, @"Error running genstrings");
		
		// find output files
		NSArray *genstrings1files = [fileManager contentsOfDirectoryAtPath:genstrings1OutPath error:NULL];
		NSArray *genstrings2files = [fileManager contentsOfDirectoryAtPath:genstrings2OutPath error:NULL];
		
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

		
		
		
		
//		NSArray *arguments = [NSArray arrayWithObjects:@"/usr/bin/genstrings", nil, [oneCaseURL path], [NSString stringWithFormat:@"-o \"%@\"", genstrings1OutPath], nil];
		
//		[self runScriptWithArguments:arguments];
		
		
		
		//STFail(@"'%@' failed", [self testCaseNameFromURL:oneCaseURL]);
		
		// cleanup
		//[[NSFileManager defaultManager] removeItemAtPath:tempPath error:NULL];
	}
}




@end
