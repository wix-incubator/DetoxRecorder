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

+ (NSMutableArray<UIView*>*)dtxrec_findViewsInAllWindowsPassingPredicate:(NSPredicate*)predicate;
+ (NSMutableArray<UIView*>*)dtxrec_findViewsInKeySceneWindowsPassingPredicate:(NSPredicate*)predicate;
+ (NSMutableArray<UIView*>*)dtxrec_findViewsInWindowScene:(id /* UIScene* */)scene passingPredicate:(NSPredicate*)predicate;
+ (NSMutableArray<UIView*>*)dtxrec_findViewsInWindows:(NSArray<UIWindow*>*)windows passingPredicate:(NSPredicate*)predicate;
+ (NSMutableArray<UIView*>*)dtxrec_findViewsInHierarchy:(UIView*)hierarchy passingPredicate:(NSPredicate*)predicate;
+ (NSMutableArray<UIView*>*)dtxrec_findViewsInHierarchy:(UIView*)hierarchy includingRoot:(BOOL)includingRoot passingPredicate:(NSPredicate*)predicate;

- (id)text;
- (id)placeholder;

@end
