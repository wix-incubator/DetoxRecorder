//
//  UIView+DTXDescendants.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/18/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (DTXDescendants)

+ (NSMutableArray<UIView*>*)dtx_findViewsInKeySceneWindowsPassingPredicate:(NSPredicate*)predicate;
+ (NSMutableArray<UIView*>*)dtx_findViewsInWindows:(NSArray<UIWindow*>*)windows passingPredicate:(NSPredicate*)predicate;
+ (NSMutableArray<UIView*>*)dtx_findViewsInHierarchy:(UIView*)hierarchy passingPredicate:(NSPredicate*)predicate;

@end
