//
//  _DTXCodeCommentAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 6/29/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "_DTXCodeCommentAction.h"

@implementation _DTXCodeCommentAction

- (instancetype)initWithComment:(NSString*)comment
{
	self = [super init];
	
	if(self)
	{
		_comment = comment;
	}
	
	return self;
}

- (NSString *)detoxDescription
{
	return [NSString stringWithFormat:@"//%@", _comment];
}

@end
