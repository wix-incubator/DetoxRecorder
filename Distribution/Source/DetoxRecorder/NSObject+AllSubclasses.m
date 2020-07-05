//
//  NSObject+AllSubclasses.m
//  UI
//
//  Created by Leo Natan (Wix) on 4/9/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "NSObject+AllSubclasses.h"
@import ObjectiveC;
#import "Swiftier.h"

NSArray<Class>* __DTXClassGetSubclasses(Class parentClass)
{
	int numClasses = objc_getClassList(NULL, 0);
	Class* classes = NULL;
	
	classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
	dtx_defer {
		free(classes);
	};
	numClasses = objc_getClassList(classes, numClasses);
	
	NSMutableArray *result = [NSMutableArray array];
	for (NSInteger i = 0; i < numClasses; i++)
	{
		Class superClass = classes[i];
		do
		{
			superClass = class_getSuperclass(superClass);
		}
		while(superClass && superClass != parentClass);
		
		if (superClass == nil)
		{
			continue;
		}
		
		[result addObject:classes[i]];
	}
	
	return result;
}
