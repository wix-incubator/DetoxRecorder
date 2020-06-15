//
//  UISlider+RecorderUtils.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 6/10/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "UISlider+RecorderUtils.h"

@implementation UISlider (RecorderUtils)

- (double)dtxrec_normalizedSliderPosition
{
	return (self.value - self.minimumValue) / self.maximumValue;
}

@end
