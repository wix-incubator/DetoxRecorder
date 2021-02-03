//
//  UIDatePicker+RecorderUtils.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/6/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDatePicker (RecorderUtils)

- (NSString*)dtxrec_dateFormatForDetox;
- (NSString*)dtxrec_dateStringForDetox;

@end

NS_ASSUME_NONNULL_END
