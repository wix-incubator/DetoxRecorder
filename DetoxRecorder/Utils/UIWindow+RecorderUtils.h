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

@property (nonatomic, strong, class, readonly, nullable) UIWindow* dtx_keyWindow NS_SWIFT_NAME(dtx_keyWindow);
@property (nonatomic, strong, class, readonly) NSArray<UIWindow*>* dtx_allKeyWindowSceneWindows;

+ (NSArray<UIWindow*>*)dtx_allWindows;
+ (NSArray<UIWindow*>*)dtx_allWindowsForScene:(nullable UIWindowScene*)scene;
+ (void)dtx_enumerateAllWindowsUsingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block;
+ (void)dtx_enumerateKeyWindowSceneWindowsUsingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block;
+ (void)dtx_enumerateWindowsInScene:(nullable UIWindowScene*)scene usingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
