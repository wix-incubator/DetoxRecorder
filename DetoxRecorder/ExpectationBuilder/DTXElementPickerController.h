//
//  DTXElementPickerController.h
//  DetoxRecorder
//
//  Created by Leo Natan on 12/7/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DTXElementPickerController;

@protocol DTXElementPickerControllerDelegate <UINavigationControllerDelegate>

- (void)elementPickerControllerDidStartVisualPicker:(DTXElementPickerController*)elementPickerController;

@end

@interface DTXElementPickerController : UINavigationController

@property (nonatomic, weak) id<DTXElementPickerControllerDelegate> delegate;

- (void)visualElementPickerDidSelectElement:(UIView*)element;

@end

NS_ASSUME_NONNULL_END
