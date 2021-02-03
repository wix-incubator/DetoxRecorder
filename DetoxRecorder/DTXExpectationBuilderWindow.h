//
//  DTXViewSelectionWindow.h
//  DetoxRecorder
//
//  Created by Leo Natan on 12/6/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTXCaptureControlWindow.h"

NS_ASSUME_NONNULL_BEGIN

@class DTXExpectationBuilderWindow;

@protocol DTXExpectationBuilderWindowDelegate <NSObject>

- (void)expectationBuilderWindowDidEnd:(DTXExpectationBuilderWindow*)elementPicker;

@end

@interface DTXExpectationBuilderWindow : UIWindow

- (instancetype)initWithCaptureControlWindow:(DTXCaptureControlWindow*)captureControlWindow;

@property (nonatomic, strong) UIWindow* appWindow;
@property (nonatomic, weak) id<DTXExpectationBuilderWindowDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
