//
//  NSObject+RecorderUtils.m
//  DetoxRecorder
//
//  Created by Leo Natan on 12/16/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "NSObject+RecorderUtils.h"

@implementation NSObject (RecorderUtils)

- (id)_dtx_text
{
	if([self respondsToSelector:@selector(text)])
	{
		return [(UITextView*)self text];
	}
	
	static Class RCTTextView;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		RCTTextView = NSClassFromString(@"RCTTextView");
	});
	if(RCTTextView != nil && [self isKindOfClass:RCTTextView])
	{
		return [(NSTextStorage*)[self valueForKey:@"textStorage"] string];
	}
	
	return nil;
}

- (id)_dtx_placeholder
{
	if([self respondsToSelector:@selector(placeholder)])
	{
		return [(UITextField*)self placeholder];
	}
	
	return nil;
}

- (CGRect)dtx_accessibilityFrame
{
	return self.accessibilityFrame;
}

- (NSString *)dtx_text
{
	id rv = [self _dtx_text];
	if(rv == nil || [rv isKindOfClass:NSString.class])
	{
		return rv;
	}
	
	if([rv isKindOfClass:NSAttributedString.class])
	{
		return [(NSAttributedString*)rv string];
	}
	
	//Unsupported
	return nil;
}

- (NSString *)dtx_placeholder
{
	id rv = [self _dtx_placeholder];
	if(rv == nil || [rv isKindOfClass:NSString.class])
	{
		return rv;
	}
	
	if([rv isKindOfClass:NSAttributedString.class])
	{
		return [(NSAttributedString*)rv string];
	}
	
	//Unsupported
	return nil;
}

@end
