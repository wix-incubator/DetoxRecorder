//
//  _DTXTapAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "_DTXTapAction.h"

@implementation _DTXTapAction

- (instancetype)initWithView:(UIView*)view event:(UIEvent*)event isFromRN:(BOOL)isFromRN
{
	self = [super initWithElementView:view allowHierarchyTraversal:isFromRN];
	
	if(self)
	{
		BOOL atPoint = NSUserDefaults.standardUserDefaults.dtx_attemptXYRecording && event != nil;
		
		self.actionType = DTXRecordedActionTypeTap;
		if(atPoint)
		{
			CGPoint pt = [[event touchesForView:view].anyObject locationInView:view];
			self.actionArgs = @[@{@"x": @(pt.x), @"y": @(pt.y)}];
		}
		else
		{
			self.actionArgs = @[];
		}
	}
	
	return self;
}

@end
