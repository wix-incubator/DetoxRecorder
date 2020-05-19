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
}

@end

@implementation Tab1ViewController

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.tabBarItem.accessibilityIdentifier = @"Tab1";
	self.tabBarItem.title = @"Leo 1";
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.tabBarController.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:nil action:nil], [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:nil action:nil]];
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
