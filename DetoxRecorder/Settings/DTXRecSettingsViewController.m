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
	NSArray<NSArray<NSDictionary<NSString*,NSString*>*>*>* _settings;
	NSArray<NSString*>* _settingHeaders;
	NSArray<NSString*>* _settingFooters;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
	self = [super initWithStyle:style];
	
	if(self)
	{
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_done:)];
		self.navigationItem.title = @"Detox Recorder Settings";
		
		[self.tableView registerClass:_DTXRecSettingsCell.class forCellReuseIdentifier:@"SettingCell"];
		
		_settingHeaders = @[
			@"Recording Settings",
			@"Visualization"
		];
		
		_settingFooters = @[
			@"When enabled, consecutive scroll actions will be coalesced into a single action.",
			@"When enabled, there will be no visualization for recorded actions."
		];
		
		_settings = @[
			@[
				@{@"Precise Tap Coordinates": NSStringFromSelector(@selector(dtxrec_attemptXYRecording))},
				@{@"Coalesce Scroll Events": NSStringFromSelector(@selector(dtxrec_coalesceScrollEvents))}
			],
			@[
				@{@"Disable Visualizations": NSStringFromSelector(@selector(dtxrec_disableVisualizations))},
			]
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
	NSIndexPath* ip = [self.tableView indexPathForCell:cell];
	NSString* userDefaultsKey = _settings[ip.section][ip.row][cell.textLabel.text];
	
	[NSUserDefaults.standardUserDefaults setBool:sender.on forKey:userDefaultsKey];
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString* rv = _settingHeaders[section];
	
	if([rv isKindOfClass:NSNull.class])
	{
		return nil;
	}
	
	return rv;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	NSString* rv = _settingFooters[section];
	
	if([rv isKindOfClass:NSNull.class])
	{
		return nil;
	}
	
	return rv;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return _settings.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _settings[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	auto cell = [tableView dequeueReusableCellWithIdentifier:@"SettingCell"];
	cell.textLabel.text = _settings[indexPath.section][indexPath.row].allKeys.firstObject;
	
	NSString* userDefaultsKey = _settings[indexPath.section][indexPath.row][cell.textLabel.text];
	
	UISwitch* sw = [UISwitch new];
	sw.on = [NSUserDefaults.standardUserDefaults boolForKey:userDefaultsKey];
	[sw addTarget:self action:@selector(_switchTapped:) forControlEvents:UIControlEventPrimaryActionTriggered];
	
	cell.accessoryView = sw;
	
	return cell;
}

@end
