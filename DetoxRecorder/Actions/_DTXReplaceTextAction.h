//
//  _DTXReplaceTextAction.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecordedAction-Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface _DTXReplaceTextAction : DTXRecordedAction

- (nullable instancetype)initWithView:(UIView*)view text:(NSString*)text;

@end

NS_ASSUME_NONNULL_END
