//
//  ViewController.m
//  UI
//
//  Created by Leo Natan (Wix) on 4/8/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UIPickerViewDataSource, UIPickerViewDelegate>
{
	NSArray<NSArray<NSString*>*>* _components;
}

@end

@implementation ViewController

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	_components = @[@[@"a", @"b", @"c"], @[@"1", @"2", @"3"], @[@"!", @"@", @"#"]];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
}

- (IBAction)tapView:(id)sender
{
	
}

- (IBAction)longPressView:(UILongPressGestureRecognizer*)sender
{
	if (sender.state == UIGestureRecognizerStateEnded) {
		NSLog(@"UIGestureRecognizerStateEnded");
		//Do Whatever You want on End of Gesture
	}
	else if (sender.state == UIGestureRecognizerStateBegan){
		NSLog(@"UIGestureRecognizerStateBegan.");
		//Do Whatever You want on Began of Gesture
	}
}

- (IBAction)tapButton:(id)sender
{
	
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return _components.count;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return _components[component].count;
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	return _components[component][row];
}

@end
