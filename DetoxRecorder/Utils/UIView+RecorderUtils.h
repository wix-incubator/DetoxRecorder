//
//  UIView+RecorderUtils.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/18/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (RecorderUtils)

+ (NSMutableArray<UIView*>*)dtxrec_findViewsInKeySceneWindowsPassingPredicate:(NSPredicate*)predicate;
+ (NSMutableArray<UIView*>*)dtxrec_findViewsInWindows:(NSArray<UIWindow*>*)windows passingPredicate:(NSPredicate*)predicate;
+ (NSMutableArray<UIView*>*)dtxrec_findViewsInHierarchy:(UIView*)hierarchy passingPredicate:(NSPredicate*)predicate;

@end
