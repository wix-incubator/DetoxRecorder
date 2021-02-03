//
//  DTXRecSettingsMultipleChoiceController.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 7/20/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DTXRecSettingsMultipleChoiceController : UITableViewController

@property (nonatomic, copy) NSString* userDefaultsKeyPath;
@property (nonatomic, copy) NSArray<NSString*>* options;

@end

NS_ASSUME_NONNULL_END
