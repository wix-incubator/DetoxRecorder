//
//  _DTXReplaceTextAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "_DTXReplaceTextAction.h"

@implementation _DTXReplaceTextAction

- (instancetype)initWithView:(UIView*)view text:(NSString*)text
{
	self = [super initWithElementView:view allowHierarchyTraversal:NO];
	
	if(self)
	{
		[self updateReplaceTextActionWithView:view text:text];
		self.allowsUpdates = YES;
	}
	
	return self;
}

- (BOOL)updateReplaceTextActionWithView:(UIView*)view text:(NSString*)text
{
	if(text.length > 0)
	{
		self.actionType = DTXRecordedActionTypeReplaceText;
		self.actionArgs = @[text];
	}
	else
	{
		self.actionType = DTXRecordedActionTypeClearText;
	}
	
	return YES;
}

- (NSString *)detoxDescription
{
	if([self.actionArgs.firstObject isEqualToString:@"\n"])
	{
		return [NSString stringWithFormat:@"await %@.tapReturnKey();", self.element.detoxDescription];
	}
	
	return super.detoxDescription;
}

@end
