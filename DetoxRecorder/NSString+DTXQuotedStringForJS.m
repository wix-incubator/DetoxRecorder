//
//  NSString+DTXQuotedStringForJS.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "NSString+DTXQuotedStringForJS.h"

@implementation NSString (DTXQuotedStringForJS)

- (NSString*)_dtx_quotedStringRepresentationForJS
{
	NSMutableString* rv = [[self valueForKey:@"quotedStringRepresentation"] mutableCopy];
	[rv replaceOccurrencesOfString:@"\\U" withString:@"\\u" options:0 range:NSMakeRange(0, rv.length)];
	
	return rv;
}

@end
