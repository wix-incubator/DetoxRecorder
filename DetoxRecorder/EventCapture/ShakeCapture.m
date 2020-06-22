//
//  ShakeCapture.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 6/22/20.
//  Copyright © 2020 Wix. All rights reserved.
//

@import ObjectiveC;
#import "DTXUIInteractionRecorder.h"

@interface UIEventEnvironmentCapture : NSObject @end

@implementation UIEventEnvironmentCapture

+ (void)load
{
	SEL sel = NSSelectorFromString(@"_sendMotionEnded:");
	Class cls = NSClassFromString(@"UIEventEnvironment");
	Method m = class_getInstanceMethod(cls, sel);
	void (*orig)(id, SEL, NSUInteger) = (void*)method_getImplementation(m);
	method_setImplementation(m, imp_implementationWithBlock(^(id _self, NSUInteger zzz) {
		orig(_self, sel, zzz);
		
		[DTXUIInteractionRecorder addDeviceShake];
	}));
}

@end
