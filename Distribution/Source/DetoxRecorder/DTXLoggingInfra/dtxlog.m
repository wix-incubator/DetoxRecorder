//
//  main.m
//  dtxlog
//
//  Created by Leo Natan (Wix) on 11/5/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DTXLogging.h"
#import "dtxlog-Swift.h"

DTX_CREATE_LOG(Test)

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		dtx_log_info(@"test");
		dtx_log_fault(@"test2");
		
		swift_test_logs();
	}
	return 0;
}
