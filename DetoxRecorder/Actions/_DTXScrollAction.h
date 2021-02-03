//
//  _DTXScrollAction.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecordedAction-Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface _DTXScrollAction : DTXRecordedAction

- (nullable instancetype)initWithScrollView:(UIScrollView*)scrollView originOffset:(CGPoint)originOffset newOffset:(CGPoint)newOffset;

@end

NS_ASSUME_NONNULL_END
