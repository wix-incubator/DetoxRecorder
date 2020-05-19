//
//  Tab2ViewController.m
//  UI
//
//  Created by Leo Natan (Wix) on 4/8/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "Tab2ViewController.h"

@interface Tab2ViewController () <UIScrollViewDelegate>
{
	IBOutlet UIScrollView* _scrollView;
}

@end

@implementation Tab2ViewController

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.tabBarItem.accessibilityIdentifier = @"Tab2";
	self.tabBarItem.title = @"Leo 2";
	
	_scrollView.panGestureRecognizer.delegate = nil;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if(decelerate == NO)
	{
//		NSLog(@"👋🏻 %@", @(scrollView.contentOffset));
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
//	NSLog(@"👋🏻 %@", @(scrollView.contentOffset));
}

@end
