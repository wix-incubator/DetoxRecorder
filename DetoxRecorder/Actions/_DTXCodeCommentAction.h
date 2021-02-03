//
//  _DTXCodeCommentAction.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 6/29/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecordedAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface _DTXCodeCommentAction : DTXRecordedAction

@property (nonatomic, readonly, copy) NSString* comment;

- (instancetype)initWithComment:(NSString*)comment;

@end

NS_ASSUME_NONNULL_END
