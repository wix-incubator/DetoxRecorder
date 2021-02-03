//
//  UIDatePicker+RecorderUtils.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/6/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "UIDatePicker+RecorderUtils.h"

@implementation UIDatePicker (RecorderUtils)

- (NSString*)dtxrec_dateFormatForDetox
{
	static NSString* rv = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		rv = @"ISO8601";
	});
	return rv;
}

- (NSString*)dtxrec_dateStringForDetox
{
	return [NSISO8601DateFormatter stringFromDate:self.date timeZone:self.timeZone ?: NSTimeZone.systemTimeZone formatOptions:NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithDashSeparatorInDate | NSISO8601DateFormatWithColonSeparatorInTime | NSISO8601DateFormatWithColonSeparatorInTimeZone];
}

@end
