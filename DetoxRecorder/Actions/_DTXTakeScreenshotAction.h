//
//  _DTXTakeScreenshotAction.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecordedAction-Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface _DTXTakeScreenshotAction : DTXRecordedAction

+ (void)resetScreenshotCounter;

@property (nonatomic, readonly, copy, nullable) NSString* screenshotName;

- (instancetype)initWithName:(nullable NSString*)screenshotName;

@end

NS_ASSUME_NONNULL_END
