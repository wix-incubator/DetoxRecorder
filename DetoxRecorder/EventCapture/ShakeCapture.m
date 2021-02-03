//
//  ShakeCapture.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 6/22/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

@import ObjectiveC;
#import "DTXUIInteractionRecorder.h"

@interface UIEventEnvironmentCapture : NSObject @end

@implementation UIEventEnvironmentCapture

+ (void)load
{
	SEL sel = NSSelectorFromString(@"sendEvent:");
	Class cls = NSClassFromString(@"UIApplication");
	Method m = class_getInstanceMethod(cls, sel);
	void (*orig)(id, SEL, UIEvent*) = (void*)method_getImplementation(m);
	method_setImplementation(m, imp_implementationWithBlock(^(id _self, UIEvent* event) {
		orig(_self, sel, event);
		
		if(event.subtype == UIEventSubtypeMotionShake && [[event valueForKey:@"shakeState"] unsignedIntValue] == 1)
		{
			[DTXUIInteractionRecorder addDeviceShake];
		}
	}));
}

@end
