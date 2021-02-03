//
//  UITableView+SelectionCapture.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 6/15/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "UITableView+SelectionCapture.h"
#import "DTXUIInteractionRecorder.h"
@import ObjectiveC;

static void* _DTXHighlightedCell = &_DTXHighlightedCell;
static void* _DTXCellTouchEvent = &_DTXCellTouchEvent;

@interface UITableView ()

- (_Bool)_highlightRowAtIndexPath:(id)arg1 animated:(_Bool)arg2 scrollPosition:(long long)arg3 usingPresentationValues:(_Bool)arg4;
- (void)_userSelectRowAtPendingSelectionIndexPath:(id)arg1;
- (void)unhighlightRowAtIndexPath:(id)arg1 animated:(_Bool)arg2;

@end

@implementation UITableView (SelectionCapture)

- (void)_dtxrec_unhighlightRowAtIndexPath:(id)arg1 animated:(_Bool)arg2
{
	[self _dtxrec_unhighlightRowAtIndexPath:arg1 animated:arg2];
	
	UITableViewCell* cell = [self cellForRowAtIndexPath:arg1];
	[cell dtx_attachObject:nil forKey:_DTXCellTouchEvent];
}

- (void)_dtxrec_userSelectRowAtPendingSelectionIndexPath:(id)arg1
{
	UITableViewCell* cell = [self cellForRowAtIndexPath:arg1];
	if(cell)
	{
		UIEvent* event = [cell dtx_attachedObjectForKey:_DTXCellTouchEvent];
		[DTXUIInteractionRecorder addTapWithView:cell withEvent:event];
	}
	
	[self _dtxrec_userSelectRowAtPendingSelectionIndexPath:arg1];
}

- (void)_dtxrec_touchesBegan:(id)arg1 withEvent:(UIEvent*)arg2
{
	[self _dtxrec_touchesBegan:arg1 withEvent:arg2];
	
	NSIndexPath* ip = [self dtx_attachedObjectForKey:_DTXHighlightedCell];
	if(ip)
	{
		UITableViewCell* cell = [self cellForRowAtIndexPath:ip];
		[cell dtx_attachObject:arg2 forKey:_DTXCellTouchEvent];
		[self dtx_attachObject:nil forKey:_DTXHighlightedCell];
	}
}

- (BOOL)_dtxrec_highlightRowAtIndexPath:(id)arg1 animated:(_Bool)arg2 scrollPosition:(long long)arg3 usingPresentationValues:(_Bool)arg4
{
	BOOL rv = [self _dtxrec_highlightRowAtIndexPath:arg1 animated:arg2 scrollPosition:arg3 usingPresentationValues:arg4];
	
	if(rv)
	{
		[self dtx_attachObject:arg1 forKey:_DTXHighlightedCell];
	}
	
	return rv;
}

+ (void)load
{
	DTXSwizzleMethod(self, @selector(_highlightRowAtIndexPath:animated:scrollPosition:usingPresentationValues:), @selector(_dtxrec_highlightRowAtIndexPath:animated:scrollPosition:usingPresentationValues:), NULL);
	DTXSwizzleMethod(self, @selector(touchesBegan:withEvent:), @selector(_dtxrec_touchesBegan:withEvent:), NULL);
	DTXSwizzleMethod(self, @selector(_userSelectRowAtPendingSelectionIndexPath:), @selector(_dtxrec_userSelectRowAtPendingSelectionIndexPath:), NULL);
	DTXSwizzleMethod(self, @selector(unhighlightRowAtIndexPath:animated:), @selector(_dtxrec_unhighlightRowAtIndexPath:animated:), NULL);
}

@end
