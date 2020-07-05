//
//  UIInputCapture.m
//  UI
//
//  Created by Leo Natan (Wix) on 4/10/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "UIInputCapture.h"
#import "DTXUIInteractionRecorder.h"
@import UIKit;

static UIResponder* currentFirstResponder;

@implementation UIInputCapture

+ (void)_handleTextChangeForView:(UIView<UITextInput>*)view
{
	[DTXUIInteractionRecorder addTextChangeEvent:view];
}

+ (void)_textFieldContentDidChange:(UITextField*)textField
{
	[self _handleTextChangeForView:textField];
}

+ (void)_textViewContentDidChange:(NSNotification*)note
{
	[self _handleTextChangeForView:note.object];
}

+ (void)load
{
	[NSNotificationCenter.defaultCenter addObserverForName:@"UIWindowFirstResponderDidChangeNotification" object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
		__kindof UIResponder* oldResponder = currentFirstResponder;
		currentFirstResponder = note.userInfo[@"UIWindowFirstResponderUserInfoKey"];
		
		if([oldResponder isKindOfClass:UITextField.class])
		{
			UITextField* textField = (id)oldResponder;
			[textField removeTarget:self action:@selector(_textFieldContentDidChange:) forControlEvents:UIControlEventEditingChanged];
		}

		if([currentFirstResponder isKindOfClass:UITextField.class])
		{
			UITextField* textField = (id)currentFirstResponder;
			[textField addTarget:self action:@selector(_textFieldContentDidChange:) forControlEvents:UIControlEventEditingChanged];
		}
		
		if([oldResponder isKindOfClass:UITextView.class])
		{
			UITextView* textView = (id)oldResponder;
			[NSNotificationCenter.defaultCenter removeObserver:self name:UITextViewTextDidChangeNotification object:textView];
		}
		
		if([currentFirstResponder isKindOfClass:UITextView.class])
		{
			UITextView* textView = (id)currentFirstResponder;
			[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_textViewContentDidChange:) name:UITextViewTextDidChangeNotification object:textView];
		}
		
//		NSLog(@"🤦‍♂️ %@", currentFirstResponder);
	}];
}

@end
