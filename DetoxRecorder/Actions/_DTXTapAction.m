//
//  _DTXTapAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "_DTXTapAction.h"

@implementation _DTXTapAction

- (instancetype)initWithView:(UIView*)view event:(UIEvent*)event tapGestureRecognizer:(nullable UITapGestureRecognizer*)tgr isFromRN:(BOOL)isFromRN
{
	self = [super initWithElementView:view allowHierarchyTraversal:isFromRN];
	
	if(self)
	{
		BOOL atPoint = NSUserDefaults.standardUserDefaults.dtxrec_attemptXYRecording && (event != nil || tgr != nil);
		
		self.actionType = DTXRecordedActionTypeTap;
		if(atPoint)
		{
			CGPoint pt = view.center;
			if(tgr)
			{
				pt = [tgr locationInView:view];
			}
			else if(event)
			{
				NSSet<UITouch*>* touches = [event touchesForView:view];
				if(touches == nil)
				{
					touches = event.allTouches;
				}
				
				pt = [touches.anyObject locationInView:view];
			}
			
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
