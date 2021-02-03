//
//  _DTXTapAction.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecordedAction-Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface _DTXTapAction : DTXRecordedAction

- (nullable instancetype)initWithView:(UIView*)view event:(nullable UIEvent*)event tapGestureRecognizer:(nullable UITapGestureRecognizer*)tgr isFromRN:(BOOL)isFromRN;

@end

NS_ASSUME_NONNULL_END
