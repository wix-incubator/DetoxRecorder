//
//  NSUserDefaults+RecorderUtils.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/17/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSUserDefaults (RecorderUtils)

@property (nonatomic, assign, setter=dtx_setAttemptXYRecording:) BOOL dtx_attemptXYRecording;

@end

NS_ASSUME_NONNULL_END
