//
//  DTXElementSearchController.m
//  DetoxRecorder
//
//  Created by Leo Natan on 12/15/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXElementSearchController.h"

@interface UIViewController ()

- (void)_dismissPresentation:(id)sender;

@end

@interface _DTXElementSearchController : UITableViewController @end

@interface _DTXElementSearchController () <UISearchControllerDelegate, UISearchBarDelegate>
{
	UISearchBar* _searchBar;
}

@end

@implementation _DTXElementSearchController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"Search";
	
	_searchBar = [UISearchBar new];
	_searchBar.scopeButtonTitles = @[@"Any", @"Identifier", @"Text", @"Label"];
	_searchBar.showsScopeBar = YES;
	_searchBar.showsCancelButton = YES;
	_searchBar.searchBarStyle = UISearchBarStyleMinimal;
	_searchBar.placeholder = @"Search";
	_searchBar.delegate = self;
	[_searchBar setValue:@NO forKey:@"autoDisableCancelButton"];
	
	self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
	self.tableView.hidden = YES;
	
	self.navigationItem.titleView = _searchBar;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[_searchBar becomeFirstResponder];
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
	return UIBarPositionTopAttached;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[self.navigationController _dismissPresentation:nil];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if(searchText.length == 0)
	{
		self.tableView.hidden = YES;
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	if(searchBar.text.length == 0)
	{
		self.tableView.hidden = YES;
		return;
	}
	
	self.tableView.hidden = NO;
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
	
}

@end

@interface DTXElementSearchController () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIGestureRecognizerDelegate>

@end

@implementation DTXElementSearchController

- (instancetype)init
{
	self = [super initWithRootViewController:[_DTXElementSearchController new]];
	
	if(self)
	{
		UITapGestureRecognizer* tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_dismissPresentation:)];
		tgr.delegate = self;
		[self.view addGestureRecognizer:tgr];
		
		self.modalPresentationStyle = UIModalPresentationCustom;
		self.transitioningDelegate = self;
//		self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		
		self.navigationBarHidden = YES;
	}
	
	return self;
}

- (void)_dismissPresentation:(UITapGestureRecognizer*)sender
{
	if(self.navigationController)
	{
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	}
	else
	{
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
	return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
	return self;
}

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext
{
	return transitionContext.isAnimated ? 0.5 : 0.0;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
	UIViewController* from = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
 	UIViewController* to = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	
	if(to == self)
	{
		to.view.backgroundColor = UIColor.clearColor;
		[transitionContext.containerView addSubview:to.view];
		[UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 usingSpringWithDamping:500 initialSpringVelocity:0.0 options:0 animations:^{
			to.view.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.15];
			[self setNavigationBarHidden:NO animated:YES];
		} completion:^(BOOL finished) {
			[transitionContext completeTransition:finished];
		}];
	}
	else
	{
		[self.topViewController.view setHidden:YES];
		
		[UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 usingSpringWithDamping:500 initialSpringVelocity:0.0 options:0 animations:^{
			from.view.backgroundColor = UIColor.clearColor;
			[self setNavigationBarHidden:YES animated:YES];
		} completion:^(BOOL finished) {
			[from.view removeFromSuperview];
			[self.topViewController.view setHidden:NO];
			[transitionContext completeTransition:finished];
		}];
	}
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	if([touch.view isDescendantOfView:self.topViewController.view])
	{
		return NO;
	}
	
	return YES;
}

@end
