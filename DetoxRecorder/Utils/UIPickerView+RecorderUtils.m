//
//  UIPickerView+RecorderUtils.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/6/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "UIPickerView+RecorderUtils.h"
#import "UIView+RecorderUtils.h"
#import "DTXAppleInternals.h"

@implementation UIPickerView (RecorderUtils)

- (NSString*)dtxrec_valueForComponent:(NSInteger)component
{
	NSString* value = nil;
	
	NSInteger row = [self selectedRowInComponent:component];
	if([self.delegate respondsToSelector:@selector(pickerView:titleForRow:forComponent:)])
	{
		value = [self.delegate pickerView:self titleForRow:row forComponent:component];
	}
	if([self.delegate respondsToSelector:@selector(pickerView:attributedTitleForRow:forComponent:)])
	{
		value = [self.delegate pickerView:self attributedTitleForRow:row forComponent:component].string;
	}
	else if ([self.delegate respondsToSelector:@selector(pickerView:viewForRow:forComponent:reusingView:)])
	{
		UIView* view = [self.delegate pickerView:self viewForRow:row forComponent:component reusingView:nil];
		if([view isKindOfClass:UILabel.class])
		{
			value = [(UILabel*)view text];
		}
		else
		{
			UILabel* label = (id)[UIView dtx_findViewsInHierarchy:view passingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
				return [evaluatedObject isKindOfClass:UILabel.class];
			}]].firstObject;
			value = label.text;
		}
	}
	
	return value;
}

- (NSInteger)dtxrec_componentForColumnView:(UIView*)view
{
	NSInteger component = 0;
	for(component = 0; component < self.numberOfComponents; component++)
	{
		if([[self tableViewForColumn:component] _containerView] == view)
		{
			break;
		}
	}
	
	return component;
}

- (BOOL)dtxrec_isPartOfDatePicker
{
	return [self isKindOfClass:NSClassFromString(@"_UIDatePickerView")];
}

@end
