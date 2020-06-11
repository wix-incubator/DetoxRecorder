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
		[NSUserDefaults.standardUserDefaults registerDefaults:@{@"dtx_attemptXYRecording": @NO}];
		[NSUserDefaults.standardUserDefaults registerDefaults:@{@"dtx_coalesceScrollEvents": @NO}];
	}
}

- (BOOL)dtx_attemptXYRecording
{
	return [self boolForKey:@"dtx_attemptXYRecording"];
}

- (void)dtx_setAttemptXYRecording:(BOOL)dtx_attemptXYRecording
{
	[self setBool:dtx_attemptXYRecording forKey:@"dtx_attemptXYRecording"];
}

- (BOOL)dtx_coalesceScrollEvents
{
	return [self boolForKey:@"dtx_coalesceScrollEvents"];
}

- (void)dtx_setCoalesceScrollEvents:(BOOL)dtx_coalesceScrollEvents
{
	[self setBool:dtx_coalesceScrollEvents forKey:@"dtx_coalesceScrollEvents"];
}

@end
