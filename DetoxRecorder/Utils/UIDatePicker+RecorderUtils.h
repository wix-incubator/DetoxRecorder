//
//  UIDatePicker+RecorderUtils.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/6/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDatePicker (RecorderUtils)

- (NSString*)dtx_dateFormatForDetox;
- (NSString*)dtx_dateStringForDetox;

@end

NS_ASSUME_NONNULL_END
