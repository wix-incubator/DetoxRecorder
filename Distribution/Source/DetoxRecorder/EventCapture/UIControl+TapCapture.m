//
//  UIControl+TapCapture.m
//  UI
//
//  Created by Leo Natan (Wix) on 4/8/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "UIControl+TapCapture.h"
@import ObjectiveC;
#import "DTXUIInteractionRecorder.h"
#import "DTXCaptureControlWindow.h"

@interface UIControl ()

- (void)_sendActionsForEvents:(UIControlEvents)arg1 withEvent:(UIEvent *)arg2;

@end

@implementation UIControl (TapCapture)

__unused static NSString* translateControlEventsToString(UIControlEvents arg)
{
	NSMutableString* rv = [NSMutableString new];
	
	if((arg & UIControlEventTouchDown) != 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@","];
		}
		[rv appendString:@"UIControlEventTouchDown"];
	}
	if((arg & UIControlEventTouchDownRepeat) != 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@","];
		}
		[rv appendString:@"UIControlEventTouchDownRepeat"];
	}
	if((arg & UIControlEventTouchDragInside) != 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@","];
		}
		[rv appendString:@"UIControlEventTouchDragInside"];
	}
	if((arg & UIControlEventTouchDragOutside) != 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@","];
		}
		[rv appendString:@"UIControlEventTouchDragOutside"];
	}
	if((arg & UIControlEventTouchDragEnter) != 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@","];
		}
		[rv appendString:@"UIControlEventTouchDragEnter"];
	}
	if((arg & UIControlEventTouchDragExit) != 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@","];
		}
		[rv appendString:@"UIControlEventTouchDragExit"];
	}
	if((arg & UIControlEventTouchUpInside) != 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@","];
		}
		[rv appendString:@"UIControlEventTouchUpInside"];
	}
	if((arg & UIControlEventTouchUpOutside) != 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@","];
		}
		[rv appendString:@"UIControlEventTouchUpOutside"];
	}
	if((arg & UIControlEventTouchCancel) != 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@","];
		}
		[rv appendString:@"UIControlEventTouchCancel"];
	}
	if((arg & UIControlEventValueChanged) != 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@","];
		}
		[rv appendString:@"UIControlEventValueChanged"];
	}
	if((arg & UIControlEventPrimaryActionTriggered) != 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@","];
		}
		[rv appendString:@"UIControlEventPrimaryActionTriggered"];
	}
	if((arg & UIControlEventApplicationReserved) != 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@","];
		}
		[rv appendString:@"UIControlEventApplicationReserved"];
	}
	if((arg & UIControlEventSystemReserved) != 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@","];
		}
		[rv appendString:@"UIControlEventSystemReserved"];
	}
	
	return rv;
}

- (void)_dtxrec_sendActionsForEvents:(UIControlEvents)arg1 withEvent:(UIEvent *)arg2
{
	[self _dtxrec_sendActionsForEvents:arg1 withEvent:arg2];
	
	if([self isKindOfClass:NSClassFromString(@"_UITextFieldClearButton")])
	{
		//Text field clear button
		return;
	}
	
	if([self isKindOfClass:_DTXCaptureControlButton.class])
	{
		return;
	}
	
	if([self isKindOfClass:NSClassFromString(@"UICalloutBarButton")])
	{
		return;
	}
	
	if([self isKindOfClass:UITextField.class])
	{
		if(arg1 == UIControlEventEditingDidEndOnExit)
		{
			[DTXUIInteractionRecorder addTextReturnKeyEvent:(UITextField*)self];
		}
		
		return;
	}
	
	if([self isKindOfClass:UISegmentedControl.class])
	{
		if(arg1 == UIControlEventValueChanged)
		{
			UISegmentedControl* segmented = (id)self;
			UIView* tapped = [segmented accessibilityElementAtIndex:segmented.selectedSegmentIndex];
			
			[DTXUIInteractionRecorder addTapWithView:tapped withEvent:arg2];
		}
		
		return;
	}
	
	if([self isKindOfClass:UISlider.class])
	{
		if(arg1 == UIControlEventTouchUpInside)
		{
			[DTXUIInteractionRecorder addSliderAdjustEvent:(id)self withEvent:arg2];
		}
		
		return;
	}
	
	if((arg1 == UIControlEventTouchUpInside && arg2 != nil) || (arg1 == UIControlEventPrimaryActionTriggered && arg2 == nil))
	{
		if([self isKindOfClass:UIDatePicker.class])
		{
			[DTXUIInteractionRecorder addDatePickerDateChangeEvent:(id)self withEvent:arg2];
		}
		else
		{
			[DTXUIInteractionRecorder addControlTapWithControl:self withEvent:arg2];
		}
	}
}

+ (void)load
{
	@autoreleasepool {
		DTXSwizzleMethod(self, @selector(_sendActionsForEvents:withEvent:), @selector(_dtxrec_sendActionsForEvents:withEvent:), NULL);
	}
}

@end
