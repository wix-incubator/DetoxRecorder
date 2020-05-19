//
//  NSString+DTXQuotedStringForJS.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DTXQuotedStringForJS)

- (NSString*)_dtx_quotedStringRepresentationForJS;

@end
