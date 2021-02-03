//
//  UISlider+RecorderUtils.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 6/10/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UISlider (RecorderUtils)

@property (nonatomic, readonly, getter=dtxrec_normalizedSliderPosition) double dtxrec_normalizedSliderPosition;

@end

NS_ASSUME_NONNULL_END
