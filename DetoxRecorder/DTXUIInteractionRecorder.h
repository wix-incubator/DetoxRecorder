//
//  DTXUIInteractionRecorder.h
//  UI
//
//  Created by Leo Natan (Wix) on 4/9/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

@import UIKit;

@class DTXUIInteractionRecorder;

@interface DTXUIInteractionRecorder : NSObject

+ (void)beginRecording;
+ (void)endRecording;

+ (void)addTapWithView:(UIView*)view withEvent:(UIEvent*)event;
+ (void)addControlTapWithControl:(UIControl*)control withEvent:(UIEvent*)event;
+ (void)addGestureRecognizerTap:(UIGestureRecognizer*)tgr withEvent:(UIEvent*)event;
+ (void)addRNGestureRecognizerTapTouch:(UITouch*)touch withEvent:(UIEvent*)event;

+ (void)addGestureRecognizerLongPress:(UIGestureRecognizer*)tgr duration:(NSTimeInterval)duration withEvent:(UIEvent*)event;

+ (void)addScrollEvent:(UIScrollView*)scrollView fromOriginOffset:(CGPoint)originOffset withEvent:(UIEvent*)event;
+ (void)addScrollEvent:(UIScrollView*)scrollView fromOriginOffset:(CGPoint)originOffset toNewOffset:(CGPoint)newOffset withEvent:(UIEvent*)event;
+ (void)addScrollToTopEvent:(UIScrollView*)scrollView withEvent:(UIEvent*)event;

+ (void)addDatePickerDateChangeEvent:(UIDatePicker*)datePicker withEvent:(UIEvent*)event;
+ (void)addPickerViewValueChangeEvent:(UIPickerView*)pickerView component:(NSInteger)component withEvent:(UIEvent*)event;

+ (void)addSliderAdjustEvent:(UISlider*)slider withEvent:(UIEvent*)event;

+ (void)addTextChangeEvent:(UIView<UITextInput>*)textInput;
+ (void)addTextReturnKeyEvent:(UIView<UITextInput>*)textInput;

+ (void)addTakeScreenshot;

@end
