//
//  UIWindow+RecorderUtils.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 7/7/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "UIWindow+RecorderUtils.h"

@interface UIWindowScene ()

+ (instancetype)_keyWindowScene;
@property(readonly, nonatomic) UIWindow *_keyWindow;
- (id)_allWindowsIncludingInternalWindows:(_Bool)arg1 onlyVisibleWindows:(_Bool)arg2;
+ (id)_keyboardWindowSceneForScreen:(UIScreen*)arg1 create:(_Bool)arg2;

@end

@interface UIWindow (GREYExposed)

- (id)firstResponder;
+ (instancetype)keyWindow;
+ (NSArray<UIWindow*>*)allWindowsIncludingInternalWindows:(_Bool)arg1 onlyVisibleWindows:(_Bool)arg2;

@end

@implementation UIWindow (RecorderUtils)

+ (UIWindow*)dtx_keyWindow
{
	return UIWindowScene._keyWindowScene._keyWindow;
}

+ (NSArray<UIWindow *> *)dtx_allKeyWindowSceneWindows
{
	UIWindowScene* scene = UIWindowScene._keyWindowScene;
	return [self dtx_allWindowsForScene:scene];
}

+ (NSArray<UIWindow*>*)dtx_allWindowsForScene:(UIWindowScene*)scene
{
	NSMutableArray<UIWindow*>* windows = [[self dtx_allWindows] mutableCopy];
	scene = scene ?: UIWindowScene._keyWindowScene;
	if(scene != nil)
	{
		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"windowScene == %@", scene];
		
		UIScene* keyboardScene = [UIWindowScene _keyboardWindowSceneForScreen:[scene screen] create:NO];
		if(keyboardScene != nil)
		{
			predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate, [NSPredicate predicateWithFormat:@"windowScene == %@", keyboardScene]]];
		}
		
		[windows filterUsingPredicate:predicate];
	}
	
	return windows;
}

+ (NSArray<UIWindow*>*)dtx_allWindows
{
	return [[UIWindow allWindowsIncludingInternalWindows:YES onlyVisibleWindows:NO] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hidden == NO"]];
}

+ (void)_dtx_enumerateWindows:(NSArray<UIWindow*>*)windows usingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block
{
	NSUInteger idx = 0;
	for (UIWindow * _Nonnull obj in windows.reverseObjectEnumerator)
	{
		BOOL stop = NO;
		block(obj, idx, &stop);
		if(stop == YES)
		{
			break;
		}
	}
}

+ (void)dtx_enumerateAllWindowsUsingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block
{
	[self _dtx_enumerateWindows:self.dtx_allWindows usingBlock:block];
}

+ (void)dtx_enumerateKeyWindowSceneWindowsUsingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block
{
	UIWindowScene* scene = UIWindowScene._keyWindowScene;
	[self dtx_enumerateWindowsInScene:scene usingBlock:block];
}

+ (void)dtx_enumerateWindowsInScene:(UIWindowScene*)scene usingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block
{
	[self _dtx_enumerateWindows:[self dtx_allWindowsForScene:scene] usingBlock:block];
}

- (NSString *)dtx_shortDescription
{
	CGRect frame = self.frame;
	
	return [NSString stringWithFormat:@"<%@: %p; frame = (%@ %@; %@ %@);>", self.class, self, @(frame.origin.x), @(frame.origin.y), @(frame.size.width), @(frame.size.height)];
}

@end
