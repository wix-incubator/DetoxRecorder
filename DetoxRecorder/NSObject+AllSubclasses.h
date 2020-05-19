//
//  NSObject+AllSubclasses.h
//  UI
//
//  Created by Leo Natan (Wix) on 4/9/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (AllSubclasses)

NSArray<Class>* __DTXClassGetSubclasses(Class parentClass);

@end
