//
//  DTXElementPickerController.m
//  DetoxRecorder
//
//  Created by Leo Natan on 12/7/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXElementPickerController.h"
#import "DTXPickerTypeSelectionController.h"

@interface DTXElementPickerController ()

@end

@implementation DTXElementPickerController

@dynamic delegate;

- (instancetype)init
{
	self = [super initWithRootViewController:[DTXPickerTypeSelectionController new]];
	
	if(self)
	{
		UINavigationBarAppearance* appearance = [UINavigationBarAppearance new];
		[appearance configureWithTransparentBackground];
		appearance.shadowColor = UIColor.clearColor;
		self.navigationBar.standardAppearance = appearance;
		self.navigationBar.scrollEdgeAppearance = appearance;
	}
	
	return self;
}

- (void)_startVisualPicker
{
	[self.delegate elementPickerControllerDidStartVisualPicker:self];
}

- (void)visualElementPickerDidSelectElement:(UIView*)element
{
	UIViewController* test = [UIViewController new];
	test.view.backgroundColor = UIColor.redColor;
	UIView* snapshot = [element snapshotViewAfterScreenUpdates:YES];
	[test.view addSubview:snapshot];
//	snapshot.bounds = CGRectMake(0, 0, 30, 30);
	snapshot.center = test.view.center;
	
	[self pushViewController:test animated:NO];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
	return UIStatusBarAnimationFade;
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

@end
