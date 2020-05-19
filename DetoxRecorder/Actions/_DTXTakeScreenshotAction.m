//
//  _DTXTakeScreenshotAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "_DTXTakeScreenshotAction.h"

static NSUInteger screenshotCounter;

@implementation _DTXTakeScreenshotAction

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		self.actionType = DTXRecordedActionTypeTakeScreenshot;
		self.actionArgs = @[[NSString stringWithFormat:@"Screen%@", @(++screenshotCounter)]];
	}
	
	return self;
}

@end
