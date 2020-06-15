//
//  Tab1ViewController.m
//  UI
//
//  Created by Leo Natan (Wix) on 4/8/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "Tab1ViewController.h"

@interface Tab1ViewController ()
{
	IBOutlet UITextField* _textField;
	IBOutlet UITextView* _textView;
}

@end

@implementation Tab1ViewController

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.tabBarItem.accessibilityIdentifier = @"TextTab";
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:nil action:nil], [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:nil action:nil]];
}

- (void)viewLayoutMarginsDidChange
{
	CGFloat inset = MAX(MAX(self.view.safeAreaInsets.left, self.view.layoutMargins.left / 3),
	MAX(self.view.safeAreaInsets.right, self.view.layoutMargins.right / 3));
	
	_textView.textContainerInset = UIEdgeInsetsMake(_textView.textContainerInset.top, inset, _textView.textContainerInset.bottom, inset);
	
	[super viewLayoutMarginsDidChange];
}

- (IBAction)startEditing:(id)sender
{
	
}

- (IBAction)endEditing:(id)sender
{
	
}

- (IBAction)clearKeyboard:(id)sender
{
	[self.view endEditing:YES];
}

@end
