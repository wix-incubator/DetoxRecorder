//
//  DTXRecSettingsViewController.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 6/11/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXRecSettingsViewController.h"
#import "NSUserDefaults+RecorderUtils.h"

@interface _DTXRecSettingsCell : UITableViewCell @end
@implementation _DTXRecSettingsCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier
{
	return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

@end

@implementation DTXRecSettingsViewController
{
	NSArray<NSDictionary<NSString*,NSString*>*>* _settings;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
	self = [super initWithStyle:style];
	
	if(self)
	{
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_done:)];
		self.navigationItem.title = @"Detox Recorder Settings";
		
		[self.tableView registerClass:_DTXRecSettingsCell.class forCellReuseIdentifier:@"SettingCell"];
		
		_settings = @[
			@{@"Precise Tap Coordinates": NSStringFromSelector(@selector(dtx_attemptXYRecording))},
			@{@"Coalesce Scroll Events": NSStringFromSelector(@selector(dtx_coalesceScrollEvents))},
		];
	}
	
	return self;
}

- (void)_done:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)_switchTapped:(UISwitch*)sender
{
	UITableViewCell* cell = (id)sender.superview;
	NSString* userDefaultsKey = _settings[[self.tableView indexPathForCell:cell].row][cell.textLabel.text];
	
	[NSUserDefaults.standardUserDefaults setBool:sender.on forKey:userDefaultsKey];
}

//- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//	return @"Detox Recorder Settings";
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _settings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	auto cell = [tableView dequeueReusableCellWithIdentifier:@"SettingCell"];
	cell.textLabel.text = _settings[indexPath.row].allKeys.firstObject;
	
	NSString* userDefaultsKey = _settings[indexPath.row][cell.textLabel.text];
	
	UISwitch* sw = [UISwitch new];
	sw.on = [NSUserDefaults.standardUserDefaults boolForKey:userDefaultsKey];
	[sw addTarget:self action:@selector(_switchTapped:) forControlEvents:UIControlEventPrimaryActionTriggered];
	
	cell.accessoryView = sw;
	
	return cell;
}

@end
