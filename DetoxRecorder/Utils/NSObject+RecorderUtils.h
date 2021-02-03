//
//  NSObject+RecorderUtils.h
//  DetoxRecorder
//
//  Created by Leo Natan on 12/16/20.
//  Copyright © 2020 Wix. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (RecorderUtils)

@property (nonatomic, copy, readonly) NSString* dtx_text;
@property (nonatomic, copy, readonly) NSString* dtx_placeholder;

@end

NS_ASSUME_NONNULL_END
