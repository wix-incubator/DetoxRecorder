//
//  _DTXPickerViewValueChangeAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/6/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "_DTXPickerViewValueChangeAction.h"
#import "UIPickerView+RecorderUtils.h"

@implementation _DTXPickerViewValueChangeAction

- (nullable instancetype)initWithPickerView:(UIPickerView*)pickerView component:(NSInteger)component
{
	self = [super initWithElementView:pickerView allowHierarchyTraversal:NO];
	
	if(self)
	{
		self.actionType = DTXRecordedActionTypePickerViewValueChange;
		
		NSString* value = [pickerView dtxrec_valueForComponent:component];
		if(value == nil)
		{
			return nil;
		}
		
		self.actionArgs = @[@(component), value];
	}
	
	return self;
}

@end
