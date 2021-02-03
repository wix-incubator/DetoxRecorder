//
//  NSString+SimulatorSafeTildeExpansion.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 7/21/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (SimulatorSafeTildeExpansion)

@property(readonly, copy) NSString* dtx_stringByExpandingTildeInPath;

@end

NS_ASSUME_NONNULL_END
