//
//  UIPickerView+RecorderUtils.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/6/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIPickerView (RecorderUtils)

- (nullable NSString*)dtx_valueForComponent:(NSInteger)component;
- (NSInteger)dtx_componentForColumnView:(UIView*)view;
- (BOOL)dtx_isPartOfDatePicker;

@end

NS_ASSUME_NONNULL_END
