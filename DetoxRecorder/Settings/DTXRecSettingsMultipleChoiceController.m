//
//  DTXRecSettingsMultipleChoiceController.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 7/20/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecSettingsMultipleChoiceController.h"

@implementation DTXRecSettingsMultipleChoiceController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"MultipleCell"];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    auto cell = [tableView dequeueReusableCellWithIdentifier:@"MultipleCell" forIndexPath:indexPath];
    
	cell.textLabel.text = self.options[indexPath.row];
	if([cell.textLabel.text isEqualToString:[NSUserDefaults.standardUserDefaults stringForKey:self.userDefaultsKeyPath]])
	{
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	auto cell = [tableView cellForRowAtIndexPath:indexPath];
	
	[NSUserDefaults.standardUserDefaults setObject:cell.textLabel.text forKey:self.userDefaultsKeyPath];
	
	for (NSUInteger idx = 0; idx < self.options.count; idx++)
	{
		if(indexPath.row == idx)
		{
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		else
		{
			[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]].accessoryType = UITableViewCellAccessoryNone;
		}
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
