//
//  UIScrollView+ScrollToTopCapture.m
//  UI
//
//  Created by Leo Natan (Wix) on 4/13/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "UIScrollView+ScrollToTopCapture.h"
#import "DTXUIInteractionRecorder.h"
@import ObjectiveC;

@interface UIScrollView ()

- (BOOL)_scrollToTopIfPossible:(BOOL)arg1;
- (void)_setContentOffset:(struct CGPoint)arg1 animated:(_Bool)arg2 animationCurve:(int)arg3 animationAdjustsForContentOffsetDelta:(_Bool)arg4 animation:(id)arg5;

@end

static CGPoint newContentOffset;

@implementation UIScrollView (ScrollToTopCapture)

- (BOOL)_dtxrec_scrollToTopIfPossible:(BOOL)arg1
{
	BOOL rv = [self _dtxrec_scrollToTopIfPossible:arg1];
	
	if(rv)
	{
//		NSLog(@"👋🏻 %@", @(newContentOffset));
		[DTXUIInteractionRecorder addScrollToTopEvent:self withEvent:nil];
	}
	
	return rv;
}

- (void)_dtxrec_setContentOffset:(struct CGPoint)arg1 animated:(_Bool)arg2 animationCurve:(int)arg3 animationAdjustsForContentOffsetDelta:(_Bool)arg4 animation:(id)arg5
{
	newContentOffset = arg1;
	
	[self _dtxrec_setContentOffset:arg1 animated:arg2 animationCurve:arg3 animationAdjustsForContentOffsetDelta:arg4 animation:arg5];
}

+ (void)load
{
	DTXSwizzleMethod(self, @selector(_scrollToTopIfPossible:), @selector(_dtxrec_scrollToTopIfPossible:), NULL);
	DTXSwizzleMethod(self, @selector(_setContentOffset:animated:animationCurve:animationAdjustsForContentOffsetDelta:animation:), @selector(_dtxrec_setContentOffset:animated:animationCurve:animationAdjustsForContentOffsetDelta:animation:), NULL);
}

@end
