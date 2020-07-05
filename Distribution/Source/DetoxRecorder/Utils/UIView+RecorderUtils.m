//
//  UIView+RecorderUtils.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/18/19.
//  Copyright © 2019-2020 Wix. All rights reserved.
//

#import "UIView+RecorderUtils.h"

@interface UIWindowScene ()

+ (instancetype)_keyWindowScene;

@end

@implementation UIView (RecorderUtils)

+ (void)_dtxrec_appendViewsRecursivelyFromArray:(NSArray<UIView*>*)views passingPredicate:(NSPredicate*)predicate storage:(NSMutableArray<UIView*>*)storage
{
	if(views.count == 0)
	{
		return;
	}
	
	[views enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(predicate == nil || [predicate evaluateWithObject:obj] == YES)
		{
			[storage addObject:obj];
		}
		
		if(obj.isAccessibilityElement == NO)
		{
			[self _dtxrec_appendViewsRecursivelyFromArray:obj.subviews passingPredicate:predicate storage:storage];
		}
	}];
}

+ (NSMutableArray<UIView*>*)dtxrec_findViewsInWindows:(NSArray<UIWindow*>*)windows passingPredicate:(NSPredicate*)predicate
{
	NSMutableArray<UIView*>* rv = [NSMutableArray new];
	
	[self _dtxrec_appendViewsRecursivelyFromArray:windows passingPredicate:predicate storage:rv];
	[self _dtxrec_sortViewsByCoords:rv];
	
	return rv;
}

+ (NSMutableArray<UIView*>*)dtxrec_findViewsInKeySceneWindowsPassingPredicate:(NSPredicate*)predicate
{
	NSArray<UIWindow*>* windows;
	if (@available(iOS 13.0, *))
	{
		windows = UIWindowScene._keyWindowScene.windows;
	}
	else
	{
		windows = UIApplication.sharedApplication.windows;
	}
	
	return [self dtxrec_findViewsInWindows:windows passingPredicate:predicate];
}

+ (NSMutableArray<UIView*>*)dtxrec_findViewsInHierarchy:(UIView*)hierarchy passingPredicate:(NSPredicate*)predicate
{
	return [self dtxrec_findViewsInHierarchy:hierarchy includingRoot:YES passingPredicate:predicate];
}

+ (NSMutableArray<UIView*>*)dtxrec_findViewsInHierarchy:(UIView*)hierarchy includingRoot:(BOOL)includingRoot passingPredicate:(NSPredicate*)predicate
{
	NSMutableArray<UIView*>* rv = [NSMutableArray new];
	
	[self _dtxrec_appendViewsRecursivelyFromArray:includingRoot ? @[hierarchy] : hierarchy.subviews passingPredicate:predicate storage:rv];
	[self _dtxrec_sortViewsByCoords:rv];
	
	return rv;
}

+ (void)_dtxrec_sortViewsByCoords:(NSMutableArray<UIView*>*)views
{
	[views sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:^NSComparisonResult(UIView* _Nonnull obj1, UIView* _Nonnull obj2) {
		CGRect frame1 = obj1.accessibilityFrame;
		CGRect frame2 = obj2.accessibilityFrame;
		
		return frame1.origin.y < frame2.origin.y ? NSOrderedAscending : frame1.origin.y > frame2.origin.y ? NSOrderedDescending : NSOrderedSame;
	}], [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:^NSComparisonResult(UIView* _Nonnull obj1, UIView* _Nonnull obj2) {
		CGRect frame1 = obj1.accessibilityFrame;
		CGRect frame2 = obj2.accessibilityFrame;
		
		return frame1.origin.x < frame2.origin.x ? NSOrderedAscending : frame1.origin.x > frame2.origin.x ? NSOrderedDescending : NSOrderedSame;
	}]]];
}

- (id)text
{
	Class cls = NSClassFromString(@"RCTTextView");
	if(cls != nil && [self isKindOfClass:cls])
	{
		return [(NSTextStorage*)[self valueForKey:@"textStorage"] string];
	}
	
	return nil;
}

- (id)placeholder
{
	return nil;
}

@end
