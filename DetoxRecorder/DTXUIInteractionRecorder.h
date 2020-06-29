//
//  DTXUIInteractionRecorder.h
//  UI
//
//  Created by Leo Natan (Wix) on 4/9/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class DTXUIInteractionRecorder;

@protocol DTXUIInteractionRecorderDelegate <NSObject>

@optional

- (BOOL)interactionRecorderShouldExitApp;
- (void)interactionRecorderDidAddTestCommand:(NSString*)command;
- (void)interactionRecorderDidReplaceUpdateTestCommandWithCommand:(nullable NSString*)command;
- (void)interactionRecorderDidEndRecordingWithTestCommands:(NSArray<NSString*>*)testCommands;

@end

@interface DTXUIInteractionRecorder : NSObject

@property (nonatomic, class, weak) id<DTXUIInteractionRecorderDelegate> delegate;

+ (void)beginRecording;
+ (void)endRecording;

+ (void)addTapWithView:(UIView*)view withEvent:(nullable UIEvent*)event;
+ (void)addControlTapWithControl:(UIControl*)control withEvent:(nullable UIEvent*)event;
+ (void)addGestureRecognizerTap:(UITapGestureRecognizer*)tgr withEvent:(nullable UIEvent*)event;
+ (void)addRNGestureRecognizerTapTouch:(UITouch*)touch withEvent:(nullable UIEvent*)event;

+ (void)addGestureRecognizerLongPress:(UIGestureRecognizer*)tgr duration:(NSTimeInterval)duration withEvent:(nullable UIEvent*)event;

+ (void)addScrollEvent:(UIScrollView*)scrollView fromOriginOffset:(CGPoint)originOffset withEvent:(nullable UIEvent*)event;
+ (void)addScrollEvent:(UIScrollView*)scrollView fromOriginOffset:(CGPoint)originOffset toNewOffset:(CGPoint)newOffset withEvent:(nullable UIEvent*)event;
+ (void)addScrollToTopEvent:(UIScrollView*)scrollView withEvent:(nullable UIEvent*)event;

+ (void)addDatePickerDateChangeEvent:(UIDatePicker*)datePicker withEvent:(nullable UIEvent*)event;
+ (void)addPickerViewValueChangeEvent:(UIPickerView*)pickerView component:(NSInteger)component withEvent:(nullable UIEvent*)event;

+ (void)addSliderAdjustEvent:(UISlider*)slider withEvent:(nullable UIEvent*)event;

+ (void)addTextChangeEvent:(UIView<UITextInput>*)textInput;
+ (void)addTextReturnKeyEvent:(UIView<UITextInput>*)textInput;

+ (void)addDeviceShake;

+ (void)addTakeScreenshot;
+ (void)addTakeScreenshotWithName:(nullable NSString*)screenshotName;

+ (void)addCodeComment:(NSString*)comment;

@end

NS_ASSUME_NONNULL_END
