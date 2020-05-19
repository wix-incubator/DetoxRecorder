//
//  _DTXSetDatePickerDateAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/6/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "_DTXSetDatePickerDateAction.h"
#import "UIDatePicker+RecorderUtils.h"

@implementation _DTXSetDatePickerDateAction

- (nullable instancetype)initWithDatePicker:(UIDatePicker*)datePicker
{
	self = [super initWithElementView:datePicker allowHierarchyTraversal:NO];
	
	if(self)
	{
		self.actionType = DTXRecordedActionTypeDatePickerDateChange;
		self.actionArgs = @[datePicker.dtx_dateStringForDetox, datePicker.dtx_dateFormatForDetox];
	}
	
	return self;
}

@end
