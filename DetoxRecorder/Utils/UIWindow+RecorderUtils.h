//
//  UIWindow+RecorderUtils.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 7/7/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (RecorderUtils)

@property (nonatomic, strong, class, readonly, nullable) UIWindow* dtxrec_keyWindow NS_SWIFT_NAME(dtxrec_keyWindow);
@property (nonatomic, strong, class, readonly) NSArray<UIWindow*>* dtxrec_allKeyWindowSceneWindows;

+ (NSArray<UIWindow*>*)dtxrec_allWindows;
+ (NSArray<UIWindow*>*)dtxrec_allWindowsForScene:(nullable id /* UIWindowScene* */)scene;
+ (void)dtxrec_enumerateAllWindowsUsingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block;
+ (void)dtxrec_enumerateKeyWindowSceneWindowsUsingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block;
+ (void)dtxrec_enumerateWindowsInScene:(nullable id /* UIWindowScene* */)scene usingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
