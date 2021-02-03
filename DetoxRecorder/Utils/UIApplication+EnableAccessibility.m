//
//  UIApplication+EnableAccessibility.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/18/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "UIApplication+EnableAccessibility.h"
@import Darwin;

DTX_CREATE_LOG(DetoxRecorderApplicationAccessibility)

@interface NSObject ()

- (void)setAccessibilityPreferenceAsMobile:(CFStringRef)key value:(CFBooleanRef)value notification:(CFStringRef)notification;

@end

@implementation UIApplication (EnableAccessibility)

+ (void)dtxrec_enableAccessibilityForSimulator
{
	dtx_log_info(@"Enabling accessibility for automation on Simulator.");
	static NSString *path =
	@"/System/Library/PrivateFrameworks/AccessibilityUtilities.framework/AccessibilityUtilities";
	char const *const localPath = [path fileSystemRepresentation];
	
	dlopen(localPath, RTLD_LOCAL);
	
	Class AXBackBoardServerClass = NSClassFromString(@"AXBackBoardServer");
	id server = [AXBackBoardServerClass valueForKey:@"server"];
	
	[server setAccessibilityPreferenceAsMobile:(CFStringRef)@"ApplicationAccessibilityEnabled"
										 value:kCFBooleanTrue
								  notification:(CFStringRef)@"com.apple.accessibility.cache.app.ax"];
	[server setAccessibilityPreferenceAsMobile:(CFStringRef)@"AccessibilityEnabled"
										 value:kCFBooleanTrue
								  notification:(CFStringRef)@"com.apple.accessibility.cache.ax"];
}

+ (void)load
{
	@autoreleasepool {
		[self dtxrec_enableAccessibilityForSimulator];
	}
}

@end
