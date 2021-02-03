//
//  DTXCaptureControlWindow.h
//  UI
//
//  Created by Leo Natan (Wix) on 4/11/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DTXExpectationBuilderWindow;

@interface _DTXCaptureControlButton : UIButton

@property (nonatomic, assign, getter=isDisabled) BOOL disabled;
@property (nonatomic, assign, getter=isToggled) BOOL toggled;

- (void)setImageTransform:(CGAffineTransform)transform forState:(UIControlState)state;

@end

@interface DTXCaptureControlWindow : UIWindow

@property (nonatomic, strong) DTXExpectationBuilderWindow* expectationBuilderWindow;

- (void)appear;

- (void)visualizeTakeScreenshotWithName:(NSString*)name;
- (void)visualizeShakeDevice;
- (void)visualizeAddComment:(NSString*)comment;

#if DEBUG
- (void)generateScreenshotsForDocumentation;
#endif

@end
