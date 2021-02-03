//
//  _DTXPickerViewValueChangeAction.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/6/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecordedAction-Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface _DTXPickerViewValueChangeAction : DTXRecordedAction

- (nullable instancetype)initWithPickerView:(UIPickerView*)pickerView component:(NSInteger)component;

@end

NS_ASSUME_NONNULL_END
