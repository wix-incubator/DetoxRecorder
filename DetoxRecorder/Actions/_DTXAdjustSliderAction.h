//
//  _DTXAdjustSliderAction.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 6/10/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecordedAction-Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface _DTXAdjustSliderAction : DTXRecordedAction

- (nullable instancetype)initWithSlider:(UISlider*)slider event:(nullable UIEvent*)event;

@end

NS_ASSUME_NONNULL_END
