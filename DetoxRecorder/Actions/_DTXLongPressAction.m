//
//  _DTXLongPressAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/18/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "_DTXLongPressAction.h"

@implementation _DTXLongPressAction

- (nullable instancetype)initWithView:(UIView*)view duration:(NSTimeInterval)duration event:(nullable UIEvent*)event
{
	self = [super initWithElementView:view allowHierarchyTraversal:NO];
	
	if(self)
	{
		self.actionType = DTXRecordedActionTypeLongPress;
		self.actionArgs = @[@(ceil(duration * 1000))];
	}
	
	return self;
}

@end
