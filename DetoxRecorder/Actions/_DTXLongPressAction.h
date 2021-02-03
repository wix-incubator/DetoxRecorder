//
//  _DTXLongPressAction.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/18/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecordedAction-Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface _DTXLongPressAction : DTXRecordedAction

- (nullable instancetype)initWithView:(UIView*)view duration:(NSTimeInterval)duration event:(nullable UIEvent*)event;

@end

NS_ASSUME_NONNULL_END
