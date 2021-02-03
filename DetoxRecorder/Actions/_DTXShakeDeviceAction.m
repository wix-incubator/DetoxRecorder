//
//  _DTXShakeDeviceAction.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 6/22/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "_DTXShakeDeviceAction.h"

@implementation _DTXShakeDeviceAction

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		self.actionType = DTXRecordedActionTypeDeviceShake;
	}
	
	return self;
}

@end
