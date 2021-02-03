//
//  _DTXTakeScreenshotAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "_DTXTakeScreenshotAction.h"

static NSUInteger screenshotCounter = 0;

@implementation _DTXTakeScreenshotAction

+ (void)resetScreenshotCounter
{
	screenshotCounter = 0;
}

- (instancetype)initWithName:(NSString*)screenshotName;
{
	self = [super init];
	
	if(self)
	{
		_screenshotName = screenshotName.copy;
		
		self.actionType = DTXRecordedActionTypeTakeScreenshot;
		
		screenshotCounter++;
		
		self.actionArgs = @[screenshotName.length > 0 ? screenshotName : [NSString stringWithFormat:@"Screenshot %@", @(screenshotCounter)]];
	}
	
	return self;
}

@end
