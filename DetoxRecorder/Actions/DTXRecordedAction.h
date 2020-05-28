//
//  DTXRecordedAction.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019 Wix. All rights reserved.
//

@import UIKit;
#import "DTXRecordedElement.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString* DTXRecordedActionType NS_TYPED_ENUM;

extern DTXRecordedActionType const DTXRecordedActionTypeTap;
extern DTXRecordedActionType const DTXRecordedActionTypeLongPress;
extern DTXRecordedActionType const DTXRecordedActionTypeScroll;
extern DTXRecordedActionType const DTXRecordedActionTypeScrollTo;
extern DTXRecordedActionType const DTXRecordedActionTypeReplaceText;
extern DTXRecordedActionType const DTXRecordedActionTypeDatePickerDateChange;
extern DTXRecordedActionType const DTXRecordedActionTypePickerViewValueChange;
extern DTXRecordedActionType const DTXRecordedActionTypeTakeScreenshot;

@interface DTXRecordedAction : NSObject

@property (nonatomic, strong, readonly) DTXRecordedElement* element;

@property (nonatomic, readonly, strong) DTXRecordedActionType actionType;
@property (nonatomic, readonly, strong) NSArray* actionArgs;

@property (nonatomic, readonly) BOOL allowsUpdates;

@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;

+ (nullable instancetype)tapActionWithView:(UIView*)view event:(nullable UIEvent*)event isFromRN:(BOOL)isFromRN;
+ (nullable instancetype)longPressActionWithView:(UIView*)view duration:(NSTimeInterval)duration event:(nullable UIEvent*)event;
+ (nullable instancetype)scrollActionWithView:(UIScrollView*)scrollView originOffset:(CGPoint)originOffset newOffset:(CGPoint)newOffset event:(nullable UIEvent*)event;
+ (nullable instancetype)scrollToTopActionWithView:(UIScrollView*)scrollView event:(nullable UIEvent*)event;
+ (nullable instancetype)replaceTextActionWithView:(UIView*)view text:(NSString*)text event:(nullable UIEvent*)event;
+ (nullable instancetype)returnKeyTextActionWithView:(UIView*)view event:(nullable UIEvent*)event;
+ (instancetype)takeScreenshotAction;
+ (nullable instancetype)datePickerDateChangeActionWithView:(UIDatePicker*)datePicker event:(nullable UIEvent*)event;
+ (nullable instancetype)pickerViewValueChangeActionWithView:(UIPickerView*)pickerView component:(NSInteger)component event:(nullable UIEvent*)event;

- (BOOL)updateScrollActionWithScrollView:(UIScrollView*)scrollView fromDeltaOriginOffset:(CGPoint)deltaOriginOffset toNewOffset:(CGPoint)newOffset;
- (void)enhanceScrollActionWithTargetElement:(DTXRecordedElement*)targetElement;

- (NSString*)detoxDescription;

@end

NS_ASSUME_NONNULL_END
