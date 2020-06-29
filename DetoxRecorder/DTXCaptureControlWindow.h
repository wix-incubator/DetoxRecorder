//
//  DTXCaptureControlWindow.h
//  UI
//
//  Created by Leo Natan (Wix) on 4/11/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface _DTXCaptureControlButton : UIButton

@property (nonatomic, assign, getter=isDisabled) BOOL disabled;
@property (nonatomic, assign, getter=isToggled) BOOL toggled;

@end
@interface DTXCaptureControlWindow : UIWindow

- (void)visualizeTakeScreenshotWithName:(NSString*)name;
- (void)visualizeShakeDevice;
- (void)visualizeAddComment:(NSString*)comment;

@end
