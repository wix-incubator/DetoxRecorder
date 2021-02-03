//
//  _DTXScrollToAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/5/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "_DTXScrollToAction.h"

_DTXScrollToActionDirection const _DTXScrollToActionDirectionTop = @"top";
_DTXScrollToActionDirection const _DTXScrollToActionDirectionBottom = @"bottom";
_DTXScrollToActionDirection const _DTXScrollToActionDirectionLeft = @"left";
_DTXScrollToActionDirection const _DTXScrollToActionDirectionRight = @"right";

@implementation _DTXScrollToAction

- (nullable instancetype)initWithScrollView:(UIScrollView*)scrollView direction:(_DTXScrollToActionDirection)direction
{
	self = [super initWithElementView:scrollView allowHierarchyTraversal:NO];
	
	if(self)
	{
		self.actionType = DTXRecordedActionTypeScrollTo;
		self.actionArgs = @[direction];
	}
	
	return self;
}

@end
