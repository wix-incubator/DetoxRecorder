//
//  NSUserDefaults+RecorderUtils.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/17/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "NSUserDefaults+RecorderUtils.h"
@import Darwin;

@implementation NSUserDefaults (RecorderUtils)

+ (void)load
{
	@autoreleasepool {
		[NSUserDefaults.standardUserDefaults registerDefaults:@{@"dtxrec_attemptXYRecording": @NO}];
		[NSUserDefaults.standardUserDefaults registerDefaults:@{@"dtxrec_coalesceScrollEvents": @NO}];
	}
}

- (BOOL)dtxrec_attemptXYRecording
{
	return [self boolForKey:@"dtxrec_attemptXYRecording"];
}

- (void)dtxrec_setAttemptXYRecording:(BOOL)dtxrec_attemptXYRecording
{
	[self setBool:dtxrec_attemptXYRecording forKey:@"dtxrec_attemptXYRecording"];
}

- (BOOL)dtxrec_coalesceScrollEvents
{
	return [self boolForKey:@"dtxrec_coalesceScrollEvents"];
}

- (void)dtxrec_setCoalesceScrollEvents:(BOOL)dtxrec_coalesceScrollEvents
{
	[self setBool:dtxrec_coalesceScrollEvents forKey:@"dtxrec_coalesceScrollEvents"];
}

@end
