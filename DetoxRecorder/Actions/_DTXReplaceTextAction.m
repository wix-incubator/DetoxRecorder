//
//  _DTXReplaceTextAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "_DTXReplaceTextAction.h"

@implementation _DTXReplaceTextAction

- (instancetype)initWithView:(UIView*)view text:(NSString*)text
{
	self = [super initWithElementView:view allowHierarchyTraversal:NO];
	
	if(self)
	{
		self.actionType = DTXRecordedActionTypeReplaceText;
		self.actionArgs = @[text];
	}
	
	return self;
}

@end
