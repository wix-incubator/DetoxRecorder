//
//  UIView+RecorderUtils.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/18/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIWindow+RecorderUtils.h"

@interface UIView (RecorderUtils)

+ (NSMutableArray<UIView*>*)dtx_findViewsInAllWindowsPassingPredicate:(NSPredicate*)predicate;
+ (NSMutableArray<UIView*>*)dtx_findViewsInKeySceneWindowsPassingPredicate:(NSPredicate*)predicate;
+ (NSMutableArray<UIView*>*)dtx_findViewsInWindows:(NSArray<UIWindow*>*)windows passingPredicate:(NSPredicate*)predicate;
+ (NSMutableArray<UIView*>*)dtx_findViewsInHierarchy:(id)hierarchy passingPredicate:(NSPredicate*)predicate;
+ (NSMutableArray<UIView*>*)dtx_findViewsInHierarchy:(id)hierarchy includingRoot:(BOOL)includingRoot passingPredicate:(NSPredicate*)predicate;

@end
