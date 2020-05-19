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
		
		[NSUserDefaults.standardUserDefaults registerDefaults:@{@"detoxrecorder_attemptXYRecording": @NO}];
	}
}

- (BOOL)dtx_attemptXYRecording
{
	return [self boolForKey:@"detoxrecorder_attemptXYRecording"];
}

- (void)dtx_setAttemptXYRecording:(BOOL)dtx_attemptXYRecording
{
	[self setBool:dtx_attemptXYRecording forKey:@"detoxrecorder_attemptXYRecording"];
}

@end
