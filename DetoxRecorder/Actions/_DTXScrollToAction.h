//
//  _DTXScrollToAction.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/5/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecordedAction-Private.h"

typedef NSString* _DTXScrollToActionDirection NS_TYPED_ENUM;

NS_ASSUME_NONNULL_BEGIN

extern _DTXScrollToActionDirection const _DTXScrollToActionDirectionTop;
extern _DTXScrollToActionDirection const _DTXScrollToActionDirectionBottom;
extern _DTXScrollToActionDirection const _DTXScrollToActionDirectionLeft;
extern _DTXScrollToActionDirection const _DTXScrollToActionDirectionRight;

@interface _DTXScrollToAction : DTXRecordedAction

- (nullable instancetype)initWithScrollView:(UIScrollView*)scrollView direction:(_DTXScrollToActionDirection)direction;

@end

NS_ASSUME_NONNULL_END
