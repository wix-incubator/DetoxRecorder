//
//  DTXPickerTypeSelectionController.m
//  DetoxRecorder
//
//  Created by Leo Natan on 12/7/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXPickerTypeSelectionController.h"
#import "DTXElementSearchController.h"

@interface UIViewController ()

- (void)_startVisualPicker;

@end

@interface DTXPickerTypeSelectionController ()

@end

@implementation DTXPickerTypeSelectionController

static UIButton* _DTXButtonWithTitleSymbol(NSString* text, NSString* symbolName)
{
	UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
	
	NSTextAttachment* att = [NSTextAttachment new];
	att.image = [[UIImage systemImageNamed:symbolName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	
	NSMutableAttributedString* rv = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", text] attributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1]}];
	[rv appendAttributedString:[NSAttributedString attributedStringWithAttachment:att]];
	
	[button setAttributedTitle:rv forState:UIControlStateNormal];
	[button sizeToFit];
	
	return button;
}

- (void)viewDidLoad
{
	
	NSString* forward = @"chevron.right";
	if(@available(iOS 14.0, *))
	{
		forward = @"chevron.forward";
	}
	
	UIButton* visually = _DTXButtonWithTitleSymbol(@"Select Visually", forward);
	[visually addTarget:self action:@selector(_visually:) forControlEvents:UIControlEventPrimaryActionTriggered];
	UIButton* search = _DTXButtonWithTitleSymbol(@"Search", forward);
	[search addTarget:self action:@selector(_search:) forControlEvents:UIControlEventPrimaryActionTriggered];
	
	self.title = @"Expectation Builder";
	
	UIStackView* buttons = [[UIStackView alloc] initWithArrangedSubviews:@[visually, search]];
	buttons.spacing = 20;
	buttons.axis = UILayoutConstraintAxisVertical;
	buttons.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self.view addSubview:buttons];
	
	[NSLayoutConstraint activateConstraints:@[
		[self.view.centerXAnchor constraintEqualToAnchor:buttons.centerXAnchor],
		[self.view.centerYAnchor constraintEqualToAnchor:buttons.centerYAnchor],
	]];
}

- (void)_visually:(UIButton*)sender
{
	dispatch_block_t handler = ^ {
		[self.navigationController _startVisualPicker];
	};
	
	if([NSUserDefaults.standardUserDefaults boolForKey:@"DTXRecVisualAlertHidden"])
	{
		handler();
		return;
	}
	
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Visual Element Selection" message:@"In visual element selection, tap on the element you'd like to select. The system will attempt to select the most suitable element. You will have the chance to fine-tune the element selection." preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:@"Start" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		handler();
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Don't Show Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[NSUserDefaults.standardUserDefaults setBool:YES forKey:@"DTXRecVisualAlertHidden"];
		handler();
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)_search:(UIButton*)sender
{
	DTXElementSearchController* searchController = [DTXElementSearchController new];
//	UISearchController* searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	
	[self presentViewController:searchController animated:YES completion:nil];
}

@end
