//
//  _DTXScrollAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "_DTXScrollAction.h"

#define ASSERT_ALLOWS_UPDATES NSParameterAssert(self.allowsUpdates == YES);

@interface _DTXScrollAction ()

@property (nonatomic) BOOL isScrollToVisible;
@property (nonatomic) CGPoint originOffset;
@property (nonatomic, strong) DTXRecordedElement* targetElement;

@end

static BOOL DTXUpdateScrollAction(_DTXScrollAction* action, UIScrollView* scrollView, CGPoint originOffset, CGPoint newOffset)
{
	CGFloat dx = newOffset.x - originOffset.x;
	CGFloat dy = newOffset.y - originOffset.y;
	if(dx == 0 && dy == 0)
	{
		return NO;
	}
	
	NSString* dir;
	CGFloat d;
	//Implicit assumption that no multidirectional scrolls will occur
	if(dy != 0)
	{
		dir = dy > 0 ? @"down" : @"up";
		d = ABS(dy);
	}
	else
	{
		dir = dx < 0 ? @"left" : @"right";
		d = ABS(dx);
	}
	
	action.actionArgs = @[@(ABS(d)), dir];
	
	return YES;
}

@implementation _DTXScrollAction

- (nullable)initWithScrollView:(UIScrollView*)scrollView originOffset:(CGPoint)originOffset newOffset:(CGPoint)newOffset;
{
	self = [super initWithElementView:scrollView allowHierarchyTraversal:NO];
	
	if(self)
	{
		self.actionType = DTXRecordedActionTypeScroll;
		
		if(DTXUpdateScrollAction(self, scrollView, originOffset, newOffset) == NO)
		{
			self.cancelled = YES;
			
			return self;
		}
		
		
		self.originOffset = originOffset;
		
		self.allowsUpdates = YES;
	}
	
	return self;
}

- (BOOL)updateScrollActionWithScrollView:(UIScrollView*)scrollView fromDeltaOriginOffset:(CGPoint)deltaOriginOffset toNewOffset:(CGPoint)newOffset
{
	ASSERT_ALLOWS_UPDATES
	
	return DTXUpdateScrollAction(self, scrollView, self.originOffset, newOffset);
}

- (BOOL)enhanceScrollActionWithTargetElement:(DTXRecordedElement*)targetElement
{
	ASSERT_ALLOWS_UPDATES
	
	if([targetElement isEqualToElement:self.element] == YES || [targetElement elementSuperviewChainContainsElement:self.element] == NO)
	{
		return NO;
	}
	
	self.isScrollToVisible = YES;
	self.allowsUpdates = NO;
	
	NSMutableArray* args = self.actionArgs.mutableCopy;
	args[0] = @50;
	self.actionArgs = args;

	self.targetElement = targetElement;
	
	return YES;
}

- (NSString*)detoxDescription;
{
	if(self.isScrollToVisible == NO)
	{
		return [super detoxDescription];
	}
	
	return [NSString stringWithFormat:@"await waitFor(%@).toBeVisible().whileElement(%@).scroll(%@, \"%@\");", self.targetElement.detoxDescription, self.element.detoxDescription, self.actionArgs.firstObject, self.actionArgs.lastObject];
}

@end
