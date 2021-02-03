//
//  NSString+SimulatorSafeTildeExpansion.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 7/21/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "NSString+SimulatorSafeTildeExpansion.h"

@implementation NSString (SimulatorSafeTildeExpansion)

- (NSString *)dtx_stringByExpandingTildeInPath
{
#if TARGET_OS_SIMULATOR
	if([self hasPrefix:@"~"] == NO)
	{
		//🤷‍♂️
		return self.stringByExpandingTildeInPath;
	}
	
	NSString* somePath = NSHomeDirectory();
	NSString* userPath = [somePath substringToIndex:[somePath rangeOfString:@"/Library"].location];
	return [self stringByReplacingOccurrencesOfString:@"~" withString:userPath options:0 range:NSMakeRange(0, 1)];
#else
	return self.stringByExpandingTildeInPath;
#endif
}

@end
