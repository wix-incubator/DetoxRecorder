//
//  DTXRecSettingsViewController.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 6/11/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecSettingsViewController.h"
#import "NSUserDefaults+RecorderUtils.h"
#import "DTXRecSettingsMultipleChoiceController.h"
#import "DTXUIInteractionRecorder-Private.h"

typedef NS_ENUM(NSUInteger, _DTXRecSettingsCellStyle) {
	_DTXRecSettingsCellStyleBool,
	_DTXRecSettingsCellStyleDouble,
	_DTXRecSettingsCellStyleMultiple
};

@interface NSObject ()

- (void)_driverClickedUp;

@end

@interface DTXRecDurationFormatter : NSFormatter

@end
@implementation DTXRecDurationFormatter
{
	NSNumberFormatter* _numberFormatter;
}

- (instancetype)init
{
	self = [super init];
	if(self)
	{
		_numberFormatter = [NSNumberFormatter new];
		_numberFormatter.maximumFractionDigits = 2;
	}
	
	return self;
}

- (NSString*)_usStringFromTimeInterval:(NSTimeInterval)ti
{
	return [NSString stringWithFormat:@"%@μs", [_numberFormatter stringFromNumber:@(ti * 1000000)]];
}

- (NSString*)_msStringFromTimeInterval:(NSTimeInterval)ti round:(BOOL)roundMs
{
	ti *= 1000;
	if(roundMs)
	{
		ti = round(ti);
	}
	
	return [NSString stringWithFormat:@"%@ms", [_numberFormatter stringFromNumber:@(ti)]];
}

- (NSString*)_hmsmsStringFromTimeInterval:(NSTimeInterval)ti
{
	NSMutableString* rv = [NSMutableString new];
	
	double hours = floor(ti / 3600);
	double minutes = floor(fmod(ti / 60, 60));
	double seconds = fmod(ti, 60);
	double secondsRound = floor(fmod(ti, 60));
	double ms = ti - floor(ti);
	
	if(hours > 0)
	{
		[rv appendFormat:@"%@h", [_numberFormatter stringFromNumber:@(hours)]];
	}
	
	if(minutes > 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@" "];
		}
		
		[rv appendFormat:@"%@m", [_numberFormatter stringFromNumber:@(minutes)]];
	}
	
	if(rv.length == 0)
	{
		if(seconds > 0)
		{
			if(rv.length != 0)
			{
				[rv appendString:@" "];
			}
			
			[rv appendFormat:@"%@s", [_numberFormatter stringFromNumber:@(seconds)]];
		}
	}
	else
	{
		if(secondsRound > 0)
		{
			[rv appendString:@" "];
			
			[rv appendFormat:@"%@s", [_numberFormatter stringFromNumber:@(secondsRound)]];
		}
		
		if(ms > 0)
		{
			[rv appendString:@" "];
			
			[rv appendString:[self _msStringFromTimeInterval:ms round:YES]];
		}
	}
	
	return rv;
}

- (NSString*)stringFromTimeInterval:(NSTimeInterval)ti
{
	if(ti < 0.001)
	{
		return [self _usStringFromTimeInterval:ti];
	}
	
	if(ti < 1.0)
	{
		return [self _msStringFromTimeInterval:ti round:NO];
	}
	
	return [self _hmsmsStringFromTimeInterval:ti];
}

- (NSString*)stringFromDate:(NSDate *)startDate toDate:(NSDate *)endDate
{
	return [self stringFromTimeInterval:endDate.timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate];
}

- (NSString *)stringForObjectValue:(id)obj
{
	return [self stringFromTimeInterval:[obj doubleValue]];
}

@end

@interface _DTXRecSettingsCell : UITableViewCell @end
@implementation _DTXRecSettingsCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier
{
	return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

@end

@interface _DTXRecSettingsCell2 : UITableViewCell @end
@implementation _DTXRecSettingsCell2

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier
{
	return [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
}

@end

@interface _DTXRecSettingsTableView : UITableView @end
@implementation _DTXRecSettingsTableView

- (void)layoutSubviews
{
	[UIView performWithoutAnimation:^{
		[super layoutSubviews];
	}];
}

@end

@implementation DTXRecSettingsViewController
{
	NSArray<NSArray<NSDictionary<NSString*,NSArray*>*>*>* _settings;
	NSArray<NSString*>* _settingHeaders;
	NSArray<NSString*>* _settingFooters;
	
	UIBarButtonItem* _doneButton;
	
	DTXRecDurationFormatter* _dcf;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
	self = [super initWithStyle:style];
	
	if(self)
	{
		self.tableView = [[_DTXRecSettingsTableView alloc] initWithFrame:CGRectZero style:style];
		_dcf = [DTXRecDurationFormatter new];
		
		[self.tableView addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) context:NULL];
		
		_doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_done:)];
		self.navigationItem.title = @"Detox Recorder Settings";
		
		[self.tableView registerClass:_DTXRecSettingsCell.class forCellReuseIdentifier:@"SettingCell"];
		[self.tableView registerClass:_DTXRecSettingsCell2.class forCellReuseIdentifier:@"SettingCell2"];
		
		_settingHeaders = @[
			@"Recording Settings",
			(id)NSNull.null,
			(id)NSNull.null,
			(id)NSNull.null,
			@"Visualization & Animations",
			(id)NSNull.null,
			@"Compatibility",
		];
		
		NSString* compatFooter;
		if([DTXUIInteractionRecorder _hasRecordedActions])
		{
			compatFooter = @"Detox Recorder will produce test files compatible with the selected Detox version.\nNote: Changing this setting will take effect during the next recording.";
		}
		else
		{
			compatFooter = @"Detox Recorder will produce test files compatible with the selected Detox version.";
		}
		
		_settingFooters = @[
			@"When enabled, consecutive scroll actions will be coalesced into a single action.",
			@"When enabled, actions performed on elements, immediately after scrolling the containing scroll view, will enhance the scroll action to waitfor for better accuracy.",
			@"When enabled, only a sinlge replaceText() call will be recorded.",
			@"The delay before a touch is categorized as a long press action in React Native.",
			@"When enabled, there will be no visualization for recorded actions.",
			@"When enabled, miscellaneous Detox Recorder animations will be minimized or disabled.",
			compatFooter,
		];
		
		_settings = @[
			@[
				@{@"Precise Tap Coordinates":
					  @[
						  NSStringFromSelector(@selector(dtxrec_attemptXYRecording)),
						  @(_DTXRecSettingsCellStyleBool)
					  ],
				},
				@{@"Coalesce Scroll Events":
					  @[
						  NSStringFromSelector(@selector(dtxrec_coalesceScrollEvents)),
						  @(_DTXRecSettingsCellStyleBool)
					  ],
				}
			],
			@[
				@{@"Enhance Scroll Events":
					  @[
						  NSStringFromSelector(@selector(dtxrec_convertScrollEventsToWaitfor)),
						  @(_DTXRecSettingsCellStyleBool)
					  ],
				}
			],
			@[
				@{@"Coalesce Text Events":
					  @[
						  NSStringFromSelector(@selector(dtxrec_coalesceTextEvents)),
						  @(_DTXRecSettingsCellStyleBool)
					  ],
				}
			],
			@[
				@{@"React Native Long Press Delay":
					  @[
						  NSStringFromSelector(@selector(dtxrec_rnLongPressDelay)),
						  @(_DTXRecSettingsCellStyleDouble),
						  @0.5,
						  @3.0
					  ],
				}
			],
			@[
				@{@"Disable Visualizations":
					  @[
						  NSStringFromSelector(@selector(dtxrec_disableVisualizations)),
						  @(_DTXRecSettingsCellStyleBool)
					  ],
				},
			],
			@[
				@{@"Minimize Other Animations":
					  @[
						  NSStringFromSelector(@selector(dtxrec_disableAnimations)),
						  @(_DTXRecSettingsCellStyleBool)
					  ],
				},
			],
			@[
				@{@"Detox Version":
					  @[
						  NSStringFromSelector(@selector(dtxrec_detoxVersionCompatibility)),
						  @(_DTXRecSettingsCellStyleMultiple),
						  @[@"17.0"],
					  ],
				},
			],
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
	NSArray* cellSettings = _settings[ip.section][ip.row][cell.textLabel.text];
	NSString* userDefaultsKey = cellSettings[0];
	
	[NSUserDefaults.standardUserDefaults setBool:sender.on forKey:userDefaultsKey];
}

- (void)_sliderSlid:(UISlider*)sender
{
	UITableViewCell* cell = (id)sender.superview;
	NSIndexPath* ip = [self.tableView indexPathForCell:cell];
	NSArray* cellSettings = _settings[ip.section][ip.row][cell.textLabel.text];
	NSString* userDefaultsKey = cellSettings[0];
	
	[NSUserDefaults.standardUserDefaults setDouble:sender.value forKey:userDefaultsKey];
	
	cell.detailTextLabel.text = [_dcf stringFromTimeInterval:DTXDoubleWithMaxFractionLength(sender.value, 3)];
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

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	auto cell = [tableView cellForRowAtIndexPath:indexPath];
	NSArray* cellSettings = _settings[indexPath.section][indexPath.row][cell.textLabel.text];
	_DTXRecSettingsCellStyle style = [cellSettings[1] unsignedIntegerValue];
	
	return style == _DTXRecSettingsCellStyleMultiple;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString* cellTitle = _settings[indexPath.section][indexPath.row].allKeys.firstObject;
	NSArray* cellSettings = _settings[indexPath.section][indexPath.row][cellTitle];
	_DTXRecSettingsCellStyle style = [cellSettings[1] unsignedIntegerValue];
	
	auto cell = [tableView dequeueReusableCellWithIdentifier:style == _DTXRecSettingsCellStyleMultiple ? @"SettingCell2" : @"SettingCell"];
	cell.textLabel.text = cellTitle;
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	cell.textLabel.minimumScaleFactor = 0.5;

	NSString* userDefaultsKey = cellSettings[0];
	
	if(style == _DTXRecSettingsCellStyleMultiple)
	{
		cell.detailTextLabel.text = [[NSUserDefaults.standardUserDefaults objectForKey:userDefaultsKey] description];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	if(style == _DTXRecSettingsCellStyleBool)
	{
		UISwitch* sw = [UISwitch new];
		sw.on = [NSUserDefaults.standardUserDefaults boolForKey:userDefaultsKey];
		[sw addTarget:self action:@selector(_switchTapped:) forControlEvents:UIControlEventPrimaryActionTriggered];
		
		cell.accessoryView = sw;
	}
	else if(style == _DTXRecSettingsCellStyleDouble)
	{
		UISlider* slider = [UISlider new];
		slider.minimumValue = [cellSettings[2] doubleValue];
		slider.maximumValue = [cellSettings[3] doubleValue];
		slider.value = [NSUserDefaults.standardUserDefaults doubleForKey:userDefaultsKey];
		[slider addTarget:self action:@selector(_sliderSlid:) forControlEvents:UIControlEventValueChanged];
		
		cell.detailTextLabel.text = [_dcf stringFromTimeInterval:DTXDoubleWithMaxFractionLength(slider.value, 3)];
		cell.accessoryView = slider;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	auto cell = [tableView cellForRowAtIndexPath:indexPath];
	NSArray* cellSettings = _settings[indexPath.section][indexPath.row][cell.textLabel.text];
	
	DTXRecSettingsMultipleChoiceController* multiple = [[DTXRecSettingsMultipleChoiceController alloc] initWithStyle:self.tableView.style];
	multiple.userDefaultsKeyPath = cellSettings[0];
	multiple.options = cellSettings[2];
	multiple.title = cell.textLabel.text;
	
	[self.navigationController pushViewController:multiple animated:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	self.preferredContentSize = self.tableView.contentSize;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.tableView reloadData];
	
	self.navigationItem.rightBarButtonItem = self.popoverPresentationController.presentingViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact ? _doneButton : nil;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
	[super traitCollectionDidChange:previousTraitCollection];
	
	self.navigationItem.rightBarButtonItem = self.popoverPresentationController.presentingViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact ? _doneButton : nil;
}

@end
