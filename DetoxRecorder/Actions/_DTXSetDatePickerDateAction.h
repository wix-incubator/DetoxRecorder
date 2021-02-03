//
//  _DTXSetDatePickerDateAction.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/6/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecordedAction-Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface _DTXSetDatePickerDateAction : DTXRecordedAction

- (nullable instancetype)initWithDatePicker:(UIDatePicker*)datePicker;

@end

NS_ASSUME_NONNULL_END
