//
//  _DTXAdjustSliderAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 6/10/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "_DTXAdjustSliderAction.h"
#import "UISlider+RecorderUtils.h"

@implementation _DTXAdjustSliderAction

- (nullable instancetype)initWithSlider:(UISlider*)slider event:(nullable UIEvent*)event
{
	self = [super initWithElementView:slider allowHierarchyTraversal:NO];
	
	if(self)
	{
		self.actionType = DTXRecordedActionTypeSliderAdjust;
		self.actionArgs = @[@(slider.dtxrec_normalizedSliderPosition)];
	}
	
	return self;
}

@end
