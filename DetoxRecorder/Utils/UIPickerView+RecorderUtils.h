//
//  UIPickerView+RecorderUtils.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/6/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIPickerView (RecorderUtils)

- (nullable NSString*)dtxrec_valueForComponent:(NSInteger)component;
- (NSInteger)dtxrec_componentForColumnView:(UIView*)view;
- (BOOL)dtxrec_isPartOfDatePicker;

@end

NS_ASSUME_NONNULL_END
