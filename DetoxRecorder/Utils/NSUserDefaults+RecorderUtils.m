//
//  NSUserDefaults+RecorderUtils.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/17/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "NSUserDefaults+RecorderUtils.h"
@import Darwin;

DTX_DIRECT_MEMBERS
@implementation NSUserDefaults (RecorderUtils)

+ (void)load
{
	@autoreleasepool {
		[NSUserDefaults.standardUserDefaults registerDefaults:@{@"dtxrec_attemptXYRecording": @NO}];
		[NSUserDefaults.standardUserDefaults registerDefaults:@{@"dtxrec_coalesceScrollEvents": @YES}];
		[NSUserDefaults.standardUserDefaults registerDefaults:@{@"dtxrec_coalesceTextEvents": @YES}];
		[NSUserDefaults.standardUserDefaults registerDefaults:@{@"dtxrec_convertScrollEventsToWaitfor": @YES}];
		[NSUserDefaults.standardUserDefaults registerDefaults:@{@"dtxrec_rnLongPressDelay": @0.5}];
		[NSUserDefaults.standardUserDefaults registerDefaults:@{@"dtxrec_recordingBarMinimized": @YES}];
		[NSUserDefaults.standardUserDefaults registerDefaults:@{@"dtxrec_detoxVersionCompatibility": @"17.0"}];
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

- (BOOL)dtxrec_coalesceTextEvents
{
	return [self boolForKey:@"dtxrec_coalesceTextEvents"];
}

- (void)dtxrec_setCoalesceTextEvents:(BOOL)dtxrec_coalesceTextEvents
{
	[self setBool:dtxrec_coalesceTextEvents forKey:@"dtxrec_coalesceTextEvents"];
}

- (BOOL)dtxrec_convertScrollEventsToWaitfor
{
	return [self boolForKey:@"dtxrec_convertScrollEventsToWaitfor"];
}

- (void)dtxrec_setConvertScrollEventsToWaitfor:(BOOL)dtxrec_convertScrollEventsToWaitfor
{
	[self setBool:dtxrec_convertScrollEventsToWaitfor forKey:@"dtxrec_convertScrollEventsToWaitfor"];
}

- (BOOL)dtxrec_disableVisualizations
{
	return [self boolForKey:@"dtxrec_disableVisualizations"];
}

- (void)dtxrec_setDisableVisualizations:(BOOL)dtxrec_disableVisualizations
{
	[self setBool:dtxrec_disableVisualizations forKey:@"dtxrec_disableVisualizations"];
}

- (BOOL)dtxrec_disableAnimations
{
	return [self boolForKey:@"dtxrec_disableAnimations"];
}

- (void)dtxrec_setDisableAnimations:(BOOL)dtxrec_disableAnimations
{
	[self setBool:dtxrec_disableAnimations forKey:@"dtxrec_disableAnimations"];
}

- (NSTimeInterval)dtxrec_rnLongPressDelay
{
	return [self doubleForKey:@"dtxrec_rnLongPressDelay"];
}

- (void)dtxrec_setRNLongPressDelay:(NSTimeInterval)dtxrec_rnLongPressDelay
{
	[self setDouble:dtxrec_rnLongPressDelay forKey:@"dtxrec_rnLongPressDelay"];
}

- (BOOL)dtxrec_recordingBarMinimized
{
	return [self boolForKey:@"dtxrec_recordingBarMinimized"];
}

- (void)dtxrec_setRecordingBarMinimized:(BOOL)dtxrec_recordingBarMinimized
{
	[self setBool:dtxrec_recordingBarMinimized forKey:@"dtxrec_recordingBarMinimized"];
}

- (NSString *)dtxrec_detoxVersionCompatibility
{
	return [self stringForKey:@"dtxrec_detoxVersionCompatibility"];
}

- (void)dtxrec_setDetoxVersionCompatibility:(NSString *)dtxrec_detoxVersionCompatibility
{
	[self setObject:dtxrec_detoxVersionCompatibility forKey:@"dtxrec_detoxVersionCompatibility"];
}

@end
