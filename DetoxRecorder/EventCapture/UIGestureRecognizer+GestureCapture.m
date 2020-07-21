//
//  UIGestureRecognizer+GestureCapture.m
//  UI
//
//  Created by Leo Natan (Wix) on 4/9/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "UIGestureRecognizer+GestureCapture.h"
#import "DTXUIInteractionRecorder.h"
#import "UIPickerView+RecorderUtils.h"
#import "DTXAppleInternals.h"
@import ObjectiveC;

@implementation UIGestureRecognizer (GestureCapture)

__unused static NSString* translateGestureRecognizerStateToString(UIGestureRecognizerState arg)
{
	switch (arg) {
		case UIGestureRecognizerStatePossible:
			return @"UIGestureRecognizerStatePossible";
		case UIGestureRecognizerStateBegan:
			return @"UIGestureRecognizerStateBegan";
		case UIGestureRecognizerStateChanged:
			return @"UIGestureRecognizerStateChanged";
		case UIGestureRecognizerStateEnded:
			return @"UIGestureRecognizerStateEnded";
		case UIGestureRecognizerStateCancelled:
			return @"UIGestureRecognizerStateCancelled";
		case UIGestureRecognizerStateFailed:
			return @"UIGestureRecognizerStateFailed";
	}
}

static void* DTXScrollViewOffsetAtBegin = &DTXScrollViewOffsetAtBegin;
static void* DTXScrollViewDecelerationObserver = &DTXScrollViewDecelerationObserver;

static void* DTXLongPressDateAtBegin = &DTXLongPressDateAtBegin;

- (void)_dtxrec_setDecelerationObserver:(id)newObserver
{
	id prevObserver = objc_getAssociatedObject(self, DTXScrollViewDecelerationObserver);
	if(prevObserver)
	{
		[NSNotificationCenter.defaultCenter removeObserver:prevObserver];
	}
	
	objc_setAssociatedObject(self, DTXScrollViewDecelerationObserver, newObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSValue*)_dtxrec_scrollOffsetValueAtGestureBegin
{
	return objc_getAssociatedObject(self, DTXScrollViewOffsetAtBegin);
}

- (void)_dtxrec_setScrollOffsetValueAtGestureBegin:(NSValue*)value
{
	objc_setAssociatedObject(self, DTXScrollViewOffsetAtBegin, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDate*)_dtxrec_longPressDateAtGestureBegin
{
	return objc_getAssociatedObject(self, DTXLongPressDateAtBegin);
}

- (void)_dtxrec_setLongPressDateAtGestureBegin:(NSDate*)value
{
	objc_setAssociatedObject(self, DTXLongPressDateAtBegin, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)_dtxrec_setView:(UIView*)view
{
	[self _dtxrec_setView:view];
	
	if([self isKindOfClass:UITapGestureRecognizer.class])
	{
		[self addTarget:self action:@selector(_dtxrec_tapAction:)];
	}
	else if([self isKindOfClass:UILongPressGestureRecognizer.class])
	{
		if([view isKindOfClass:NSClassFromString(@"UISwitchModernVisualElement")] ||
		   [self isKindOfClass:NSClassFromString(@"_UIDragLiftGestureRecognizer")] ||
		   [self isKindOfClass:NSClassFromString(@"UIVariableDelayLoupeGesture")])
		{
			return;
		}
		
		[self addTarget:self action:@selector(_dtxrec_longPressAction:)];
	}
	else if([self isKindOfClass:UIPanGestureRecognizer.class])
	{
		[self addTarget:self action:@selector(_dtxrec_panAction:)];
	}
}

- (void)_dtxrec_panAction:(UIPanGestureRecognizer*)gr
{
	if([self.view isKindOfClass:NSClassFromString(@"UIPickerColumnView")])
	{
		if(self.state == UIGestureRecognizerStateEnded)
		{
			UIPickerView* pickerView = [self.view valueForKey:@"pickerView"];
			
			if(pickerView.dtxrec_isPartOfDatePicker)
			{
				return;
			}
			
			NSInteger component = [pickerView dtxrec_componentForColumnView:self.view];
			UITableView* tv = [pickerView tableViewForColumn:component];
			
			__block id observer;
			observer = [NSNotificationCenter.defaultCenter addObserverForName:@"DidEndSmoothScrolling" object:tv queue:nil usingBlock:^(NSNotification * _Nonnull note) {
				
				[DTXUIInteractionRecorder addPickerViewValueChangeEvent:pickerView component:component withEvent:nil];
				
				[NSNotificationCenter.defaultCenter removeObserver:observer];
			}];
		}
	}
	
	if([self.view isKindOfClass:UIScrollView.class])
	{
		if(self.state == UIGestureRecognizerStateEnded)
		{
			UIScrollView* scrollView = (id)self.view;
			
			CGPoint contentOffsetAtBegin = [[self _dtxrec_scrollOffsetValueAtGestureBegin] CGPointValue];
			
			if(scrollView.isDecelerating == NO)
			{
				[DTXUIInteractionRecorder addScrollEvent:scrollView fromOriginOffset:contentOffsetAtBegin withEvent:self._activeEvents.anyObject];
			}
			else
			{
				id observer = [NSNotificationCenter.defaultCenter addObserverForName:@"_UIScrollViewDidEndDeceleratingNotification" object:scrollView queue:nil usingBlock:^(NSNotification * _Nonnull note) {
					[self _dtxrec_setScrollOffsetValueAtGestureBegin:nil];
					
					[DTXUIInteractionRecorder addScrollEvent:scrollView fromOriginOffset:contentOffsetAtBegin withEvent:self._activeEvents.anyObject];
					
					
					[self _dtxrec_setDecelerationObserver:nil];
				}];
				
				[self _dtxrec_setDecelerationObserver:observer];
			}
		}
	}
}

- (void)_dtxrec_longPressAction:(UILongPressGestureRecognizer*)gr
{
	if(self.state == UIGestureRecognizerStateBegan)
	{
		[DTXUIInteractionRecorder addGestureRecognizerLongPress:self duration:gr.minimumPressDuration withEvent:nil];
	}
}

- (void)_dtxrec_tapAction:(UITapGestureRecognizer*)gr
{
	if(self.state == UIGestureRecognizerStateRecognized)
	{
		if([self.view isKindOfClass:NSClassFromString(@"UIPickerTableViewCell")]) //User tapped on a cell of a picker view.
		{
			if(CATransform3DIsIdentity(self.view.transform3D) == NO) //The center cell is the only one with identity transform—ignore it
			{
				UITableView* tv = [self.view valueForKey:@"pickerTable"];
				UIPickerView* pickerView = [tv _pickerView];
				
				if(pickerView.dtxrec_isPartOfDatePicker)
				{
					return;
				}
				
				NSInteger component = [pickerView dtxrec_componentForColumnView:tv._containerView];
				
				__block id observer;
				observer = [NSNotificationCenter.defaultCenter addObserverForName:@"_UIScrollViewAnimationEndedNotification" object:tv queue:nil usingBlock:^(NSNotification * _Nonnull note) {
					
					[DTXUIInteractionRecorder addPickerViewValueChangeEvent:pickerView component:component withEvent:nil];
					
					[NSNotificationCenter.defaultCenter removeObserver:observer];
				}];
			}
		}
		else if(self.view != nil) //User tapped on another view
		{
			[DTXUIInteractionRecorder addGestureRecognizerTap:(id)self withEvent:self._activeEvents.anyObject];
		}
	}
}

+ (void)load
{
	@autoreleasepool {
		DTXSwizzleMethod(self, @selector(setView:), @selector(_dtxrec_setView:), NULL);
	}
}

@end

@interface UIScrollView (GestureCapture) @end
@implementation UIScrollView (GestureCapture)

- (void)_dtxrec_updatePanGesture
{
	if(self.panGestureRecognizer.state == UIGestureRecognizerStateBegan)
	{
		//Remove previous deceleration observer if user continued dragging while scroll view was decelerating.
		[self.panGestureRecognizer _dtxrec_setDecelerationObserver:nil];
		
		//For some reason UIGestureRecognizerStateBegan is called twice for scroll view pan gesture regonizers.
		if([self.panGestureRecognizer _dtxrec_scrollOffsetValueAtGestureBegin] == nil)
		{
			[self.panGestureRecognizer _dtxrec_setScrollOffsetValueAtGestureBegin:@(self.contentOffset)];
		}
	}
	
	[self _dtxrec_updatePanGesture];
}

+ (void)load
{
	@autoreleasepool {
		DTXSwizzleMethod(self, @selector(_updatePanGesture), @selector(_dtxrec_updatePanGesture), NULL);
	}
}

@end

static void* DTXRNGestureRecognizerHasTapGesture = &DTXRNGestureRecognizerHasTapGesture;
static void* DTXRNGestureRecognizerLongPressTimer = &DTXRNGestureRecognizerLongPressTimer;

@interface UIGestureRecognizer (RNGestureCapture) @end
@implementation UIGestureRecognizer (RNGestureCapture)

- (void)_dtxrec_clearTimer
{
	NSTimer* timer = objc_getAssociatedObject(self, DTXRNGestureRecognizerLongPressTimer);
	[timer invalidate];
	objc_setAssociatedObject(self, DTXRNGestureRecognizerLongPressTimer, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)_dtxrec_rn_touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	UITouch* touch = touches.anyObject;
	
	NSTimer* longPressTimer = [NSTimer scheduledTimerWithTimeInterval:NSUserDefaults.standardUserDefaults.dtxrec_rnLongPressDelay repeats:NO block:^(NSTimer * _Nonnull timer) {
		[DTXUIInteractionRecorder addRNGestureRecognizerLongPressWithTouch:touch withEvent:event];
		objc_setAssociatedObject(self, DTXRNGestureRecognizerHasTapGesture, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		[self _dtxrec_clearTimer];
	}];
	
	objc_setAssociatedObject(self, DTXRNGestureRecognizerLongPressTimer, longPressTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(self, DTXRNGestureRecognizerHasTapGesture, @(touches.count == 1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self _dtxrec_rn_touchesBegan:touches withEvent:event];
}

- (void)_dtxrec_rn_touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self _dtxrec_rn_touchesCancelled:touches withEvent:event];
	objc_setAssociatedObject(self, DTXRNGestureRecognizerHasTapGesture, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self _dtxrec_clearTimer];
}

- (void)_dtxrec_rn_touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self _dtxrec_rn_touchesMoved:touches withEvent:event];
//	objc_setAssociatedObject(self, DTXRNGestureRecognizerHasTapGesture, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//	[self _dtxrec_clearTimer];
}

- (void)_dtxrec_rn_touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self _dtxrec_rn_touchesEnded:touches withEvent:event];
	
	BOOL hasTapGesture = [objc_getAssociatedObject(self, DTXRNGestureRecognizerHasTapGesture) boolValue];
	if(hasTapGesture && touches.count == 1)
	{
		[DTXUIInteractionRecorder addRNGestureRecognizerTapWithTouch:touches.anyObject withEvent:event];
	}
	
	[self _dtxrec_clearTimer];
}

+ (void)load
{
	@autoreleasepool {
		Class RNGestureRecognizerClass = NSClassFromString(@"RCTTouchHandler");
		if(RNGestureRecognizerClass != nil)
		{
			Method m = class_getInstanceMethod(RNGestureRecognizerClass, @selector(touchesBegan:withEvent:));
			Method m2 = class_getInstanceMethod(self, @selector(_dtxrec_rn_touchesBegan:withEvent:));
			method_exchangeImplementations(m, m2);
			
			m = class_getInstanceMethod(RNGestureRecognizerClass, @selector(touchesCancelled:withEvent:));
			m2 = class_getInstanceMethod(self, @selector(_dtxrec_rn_touchesCancelled:withEvent:));
			method_exchangeImplementations(m, m2);
			
			m = class_getInstanceMethod(RNGestureRecognizerClass, @selector(touchesMoved:withEvent:));
			m2 = class_getInstanceMethod(self, @selector(_dtxrec_rn_touchesMoved:withEvent:));
			method_exchangeImplementations(m, m2);
			
			m = class_getInstanceMethod(RNGestureRecognizerClass, @selector(touchesEnded:withEvent:));
			m2 = class_getInstanceMethod(self, @selector(_dtxrec_rn_touchesEnded:withEvent:));
			method_exchangeImplementations(m, m2);
		}
	}
}

@end
