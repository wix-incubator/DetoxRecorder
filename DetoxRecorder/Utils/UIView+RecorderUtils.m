//
//  UIView+RecorderUtils.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/18/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "UIView+RecorderUtils.h"

DTX_DIRECT_MEMBERS
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
		
		[self _dtxrec_appendViewsRecursivelyFromArray:obj.subviews passingPredicate:predicate storage:storage];
	}];
}

+ (NSMutableArray<UIView*>*)dtxrec_findViewsInWindows:(NSArray<UIWindow*>*)windows passingPredicate:(NSPredicate*)predicate
{
	NSMutableArray<UIView*>* rv = [NSMutableArray new];
	
	[self _dtxrec_appendViewsRecursivelyFromArray:windows passingPredicate:predicate storage:rv];
	[self _dtxrec_sortViewsByCoords:rv];
	
	return rv;
}

+ (NSMutableArray<UIView*>*)dtxrec_findViewsInAllWindowsPassingPredicate:(NSPredicate*)predicate
{
	return [self dtxrec_findViewsInWindows:UIWindow.dtxrec_allWindows.reverseObjectEnumerator.allObjects passingPredicate:predicate];
}

+ (NSMutableArray<UIView*>*)dtxrec_findViewsInKeySceneWindowsPassingPredicate:(NSPredicate*)predicate
{
	return [self dtxrec_findViewsInWindows:UIWindow.dtxrec_allKeyWindowSceneWindows.reverseObjectEnumerator.allObjects passingPredicate:predicate];
}

+ (NSMutableArray<UIView*>*)dtxrec_findViewsInWindowScene:(id /*UIWindowScene**/)scene passingPredicate:(NSPredicate*)predicate
{
	return [self dtxrec_findViewsInWindows:[UIWindow dtxrec_allWindowsForScene:scene].reverseObjectEnumerator.allObjects passingPredicate:predicate];
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
		CGRect frame1 = obj1.dtxrec_accessibilityFrame;
		CGRect frame2 = obj2.dtxrec_accessibilityFrame;
		
		return frame1.origin.y < frame2.origin.y ? NSOrderedAscending : frame1.origin.y > frame2.origin.y ? NSOrderedDescending : NSOrderedSame;
	}], [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:^NSComparisonResult(UIView* _Nonnull obj1, UIView* _Nonnull obj2) {
		CGRect frame1 = obj1.dtxrec_accessibilityFrame;
		CGRect frame2 = obj2.dtxrec_accessibilityFrame;
		
		return frame1.origin.x < frame2.origin.x ? NSOrderedAscending : frame1.origin.x > frame2.origin.x ? NSOrderedDescending : NSOrderedSame;
	}]]];
}

- (CGRect)dtxrec_accessibilityFrame
{
	CGRect accessibilityFrame = self.accessibilityFrame;
	if(CGRectEqualToRect(accessibilityFrame, CGRectZero))
	{
		accessibilityFrame = [self.window.screen.coordinateSpace convertRect:self.bounds fromCoordinateSpace:self.coordinateSpace];
	}
	return accessibilityFrame;
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
