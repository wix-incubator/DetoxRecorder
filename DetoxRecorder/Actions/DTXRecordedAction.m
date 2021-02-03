//
//  DTXRecordedAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecordedAction.h"
#import "_DTXTapAction.h"
#import "_DTXScrollAction.h"
#import "_DTXScrollToAction.h"
#import "_DTXReplaceTextAction.h"
#import "_DTXSetDatePickerDateAction.h"
#import "_DTXPickerViewValueChangeAction.h"
#import "_DTXTakeScreenshotAction.h"
#import "_DTXLongPressAction.h"
#import "_DTXAdjustSliderAction.h"
#import "_DTXShakeDeviceAction.h"
#import "_DTXCodeCommentAction.h"
#import "NSString+QuotedStringForJS.h"

DTXRecordedActionType const DTXRecordedActionTypeTap = @"tap";
DTXRecordedActionType const DTXRecordedActionTypeLongPress = @"longPress";
DTXRecordedActionType const DTXRecordedActionTypeScroll = @"scroll";
DTXRecordedActionType const DTXRecordedActionTypeScrollTo = @"scrollTo";
DTXRecordedActionType const DTXRecordedActionTypeReplaceText = @"replaceText";
DTXRecordedActionType const DTXRecordedActionTypeClearText = @"clearText";
DTXRecordedActionType const DTXRecordedActionTypeDatePickerDateChange = @"setDatePickerDate";
DTXRecordedActionType const DTXRecordedActionTypePickerViewValueChange = @"setColumnToValue";
DTXRecordedActionType const DTXRecordedActionTypeSliderAdjust = @"adjustSliderToPosition";
DTXRecordedActionType const DTXRecordedActionTypeTakeScreenshot = @"takeScreenshot";
DTXRecordedActionType const DTXRecordedActionTypeDeviceShake = @"shake";

@implementation DTXRecordedAction

+ (instancetype)tapActionWithView:(UIView*)view event:(nullable UIEvent*)event tapGestureRecognizer:(nullable UITapGestureRecognizer*)tgr isFromRN:(BOOL)isFromRN
{
	return [[_DTXTapAction alloc] initWithView:view event:event tapGestureRecognizer:tgr isFromRN:isFromRN];
}

+ (nullable instancetype)longPressActionWithView:(UIView*)view duration:(NSTimeInterval)duration event:(nullable UIEvent*)event
{
	return [[_DTXLongPressAction alloc] initWithView:view duration:duration event:event];
}

+ (instancetype)scrollActionWithView:(UIScrollView *)scrollView originOffset:(CGPoint)originOffset newOffset:(CGPoint)newOffset event:(UIEvent*)event
{
	return [[_DTXScrollAction alloc] initWithScrollView:scrollView originOffset:originOffset newOffset:newOffset];
}

+ (nullable instancetype)scrollToTopActionWithView:(UIScrollView*)scrollView event:(nullable UIEvent*)event
{
	return [[_DTXScrollToAction alloc] initWithScrollView:scrollView direction:_DTXScrollToActionDirectionTop];
}

+ (instancetype)replaceTextActionWithView:(UIView *)view text:(NSString *)text event:(UIEvent *)event
{
	return [[_DTXReplaceTextAction alloc] initWithView:view text:text];
}

+ (nullable instancetype)returnKeyTextActionWithView:(UIView*)view event:(nullable UIEvent*)event;
{
	return [[_DTXReplaceTextAction alloc] initWithView:view text:@"\n"];
}

+ (void)resetScreenshotCounter
{
	[_DTXTakeScreenshotAction resetScreenshotCounter];
}

+ (instancetype)shakeDeviceAction
{
	return [_DTXShakeDeviceAction new];
}

+(instancetype)takeScreenshotAction
{
	return [[_DTXTakeScreenshotAction alloc] initWithName:nil];
}

+ (instancetype)takeScreenshotActionWithName:(NSString*)screenshotName
{
	return [[_DTXTakeScreenshotAction alloc] initWithName:screenshotName];
}

+ (instancetype)codeCommentAction:(NSString*)comment
{
	return [[_DTXCodeCommentAction alloc] initWithComment:comment];
}

+ (nullable instancetype)datePickerDateChangeActionWithView:(UIDatePicker*)datePicker event:(nullable UIEvent*)event
{
	return [[_DTXSetDatePickerDateAction alloc] initWithDatePicker:datePicker];
}

+ (instancetype)pickerViewValueChangeActionWithView:(UIPickerView *)pickerView component:(NSInteger)component event:(UIEvent *)event
{
	return [[_DTXPickerViewValueChangeAction alloc] initWithPickerView:pickerView component:component];
}

+ (nullable instancetype)sliderAdjustActionWithView:(UISlider*)slider event:(nullable UIEvent*)event
{
	return [[_DTXAdjustSliderAction alloc] initWithSlider:slider event:event];
}

- (instancetype)init;
{
	self = [super init];
	
	if(self)
	{
		self.allowsUpdates = NO;
	}
	
	return self;
}

- (instancetype)initWithElementView:(UIView*)view allowHierarchyTraversal:(BOOL)allowHierarchyTraversal
{
	self = [self init];
	
	if(self)
	{
		self.element = [DTXRecordedElement elementWithView:view allowHierarchyTraversal:allowHierarchyTraversal];
		if(self.element == nil)
		{
			return nil;
		}
	}
	
	return self;
}

- (BOOL)updateScrollActionWithScrollView:(UIScrollView*)scrollView fromDeltaOriginOffset:(CGPoint)deltaOriginOffset toNewOffset:(CGPoint)newOffset
{
	[self doesNotRecognizeSelector:_cmd];
	
	return NO;
}

- (BOOL)enhanceScrollActionWithTargetElement:(DTXRecordedElement*)targetElement
{
	[self doesNotRecognizeSelector:_cmd];
	
	return NO;
}

- (BOOL)updateReplaceTextActionWithView:(UIView*)view text:(NSString*)text
{
	[self doesNotRecognizeSelector:_cmd];
	
	return NO;
}

static NSDictionary* _DTXDeepDiveOnDictionary(NSDictionary* d)
{
	NSMutableDictionary* rv = [NSMutableDictionary new];
	
	[d enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		if([obj isKindOfClass:NSNumber.class])
		{
			//Turn to decimal number to preserve accuracy when printing using NSJSONSerialization 🤦‍♂️
			rv[key] = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%lf", DTXDoubleWithMaxFractionLength([obj doubleValue], 3)]];
			
			return;
		}
		
		if([obj isKindOfClass:NSDictionary.class])
		{
			rv[key] = _DTXDeepDiveOnDictionary(obj);
			
			return;
		}
		
		rv[key] = obj;
	}];
	
	return rv;
}

- (NSString*)detoxDescription;
{
	NSMutableString* rv = @"await ".mutableCopy;
	if(self.element != nil)
	{
		[rv appendString:self.element.detoxDescription];
	}
	else
	{
		[rv appendString:@"device"];
	}
	
	[rv appendFormat:@".%@(", self.actionType];
	
	NSArray* arguments = [self.actionArgs dtx_mapObjectsUsingBlock:^id _Nonnull(id _Nonnull obj, NSUInteger idx) {
		if([obj isKindOfClass:NSNumber.class])
		{
			return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%lf", DTXDoubleWithMaxFractionLength([obj doubleValue], 3)]];
		}
		if([obj isKindOfClass:NSString.class])
		{
			return [obj dtx_quotedStringRepresentationForJS];
		}
		else if([obj isKindOfClass:NSDictionary.class])
		{
			NSDictionary* fixed = _DTXDeepDiveOnDictionary(obj);
			
			return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:fixed options:0 error:NULL] encoding:NSUTF8StringEncoding];
		}
		
		return [obj description];
	}];
	if(arguments.count > 0)
	{
		[rv appendString:[arguments componentsJoinedByString:@", "]];
	}
	
	[rv appendString:@");"];
	
	return rv;
}

- (NSString *)description
{
	return self.detoxDescription;
}

@end
