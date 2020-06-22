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
	
	self.tabBarItem.accessibilityIdentifier = @"ControlsTab";
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
}

- (IBAction)tapView:(UITapGestureRecognizer*)sender
{
	[UIView animateKeyframesWithDuration:0.25 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
			sender.view.transform = CGAffineTransformMakeScale(0.85, 0.85);
		}];
		[UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
			sender.view.transform = CGAffineTransformIdentity;
		}];
	} completion:nil];
}

- (IBAction)longPressView:(UILongPressGestureRecognizer*)sender
{
	if (sender.state == UIGestureRecognizerStateEnded) {
		[UIView animateWithDuration:0.2 animations:^{
			sender.view.transform = CGAffineTransformIdentity;
		}];
	}
	else if (sender.state == UIGestureRecognizerStateBegan){
		[UIView animateWithDuration:0.2 animations:^{
			sender.view.transform = CGAffineTransformMakeScale(0.9, 0.9);
		}];
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

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
	if(motion == UIEventSubtypeMotionShake)
	{
		[UIView animateWithDuration:0.5 animations:^{
			self.view.backgroundColor = UIColor.systemRedColor;
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:0.5 animations:^{
				self.view.backgroundColor = UIColor.systemBackgroundColor;
			}];
		}];
	}
}

@end
