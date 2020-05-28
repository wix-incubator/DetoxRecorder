//
//  DTXCaptureControlWindow.m
//  UI
//
//  Created by Leo Natan (Wix) on 4/11/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "DTXCaptureControlWindow.h"
#import "DTXUIInteractionRecorder.h"
@import AudioToolbox;

@interface UIWindowScene ()

+ (instancetype)_keyWindowScene;

@end

#define SCREEN_PERCENT 0.25

const CGFloat buttonWidth = 44;

@implementation _DTXCaptureControlButton
{
	BOOL _toggled;
	UIColor* _backgroundColor;
	UIColor* _tintColor;
	UIImage* _normalStateImage;
	CGAffineTransform _normalStateImageTransform;
	UIImage* _toggledStateImage;
	CGAffineTransform _toggledStateImageTransform;
	UIImage* _disabledStateImage;
	CGAffineTransform _disabledStateImageTransform;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if(self)
	{
		self.layer.cornerRadius = buttonWidth / 2;
		self.translatesAutoresizingMaskIntoConstraints = NO;
		[self setBackgroundColor:UIColor.systemBackgroundColor];
		[self setTintColor:UIColor.labelColor];
		_normalStateImageTransform = CGAffineTransformIdentity;
		_disabledStateImageTransform = CGAffineTransformIdentity;
		_toggledStateImageTransform = CGAffineTransformIdentity;
		_disabled = NO;
		_toggled = NO;
		
		[self _refreshButtonAppearance];
	}
	
	return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
	_backgroundColor = backgroundColor;
	
	[self _refreshButtonAppearance];
}

- (void)setTintColor:(UIColor *)tintColor
{
	_tintColor = tintColor;
	
	[self _refreshButtonAppearance];
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state
{
	if(state == UIControlStateNormal)
	{
		_normalStateImage = image;
	}
	else if(state == UIControlStateDisabled)
	{
		_disabledStateImage = image;
	}
	else if(state == UIControlStateSelected)
	{
		_toggledStateImage = image;
	}
	else
	{
		NSAssert(NO, @"Unsupported state for _DTXCaptureControlButton");
	}
	
	[self _refreshButtonAppearance];
}

- (void)setImageTransform:(CGAffineTransform)transform forState:(UIControlState)state
{
	if(state == UIControlStateNormal)
	{
		_normalStateImageTransform = transform;
	}
	else if(state == UIControlStateDisabled)
	{
		_disabledStateImageTransform = transform;
	}
	else if(state == UIControlStateSelected)
	{
		_toggledStateImageTransform = transform;
	}
	else
	{
		NSAssert(NO, @"Unsupported state for _DTXCaptureControlButton");
	}
	
	[self _refreshButtonAppearance];
}

- (void)setDisabled:(BOOL)enabled
{
	_disabled = enabled;
	
	[self _refreshButtonAppearance];
}

- (void)setToggled:(BOOL)toggled
{
	_toggled = toggled;
	
	[self _refreshButtonAppearance];
}

- (void)_refreshButtonAppearance
{
	super.tintColor = _disabled ? [_tintColor colorWithAlphaComponent:0.5] : _tintColor;
	super.backgroundColor = _disabled ? [_backgroundColor colorWithAlphaComponent:0.4] : _backgroundColor;
	[super setImage:_disabled && _disabledStateImage != nil ? _disabledStateImage : _toggled && _toggledStateImage != nil ? _toggledStateImage : _normalStateImage forState:UIControlStateNormal];
	self.transform = _disabled && _disabledStateImage != nil ? _disabledStateImageTransform : _toggled && _toggledStateImage != nil ? _toggledStateImageTransform : _normalStateImageTransform;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
	[super traitCollectionDidChange:previousTraitCollection];
	
	[self _refreshButtonAppearance];
}

@end

@implementation DTXCaptureControlWindow
{
	UIView* _wrapperView;
	_DTXCaptureControlButton* _stopRecording;
	
	UIStackView* _actionButtonsStackView;
	UIScrollView* _actionButtonsScrollView;
	_DTXCaptureControlButton* _takeScreenshot;
	_DTXCaptureControlButton* _xyRecord;
	_DTXCaptureControlButton* _settings;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
	switch (self.traitCollection.userInterfaceStyle)
	{
		default:
		case UIUserInterfaceStyleLight:
			_wrapperView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
			break;
		case UIUserInterfaceStyleDark:
			_wrapperView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.5];
			break;
	}
}

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if(self)
	{
		self.rootViewController = [UIViewController new];
		_wrapperView = [UIView new];
		_wrapperView.translatesAutoresizingMaskIntoConstraints = NO;
		
		_wrapperView.layer.cornerRadius = buttonWidth * 0.6111111111;
		_wrapperView.alpha = 0.75;
		
		[self.rootViewController.view addSubview:_wrapperView];
		
		NSLayoutConstraint* constraint = [_wrapperView.topAnchor constraintEqualToAnchor:self.rootViewController.view.safeAreaLayoutGuide.topAnchor constant: buttonWidth * -0.2722222222];
		constraint.priority = UILayoutPriorityDefaultHigh;
		
		_takeScreenshot = [_DTXCaptureControlButton buttonWithType:UIButtonTypeSystem];
		[_takeScreenshot setImage:[UIImage systemImageNamed:@"camera.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17]] forState:UIControlStateNormal];
		[_takeScreenshot addTarget:self action:@selector(takeScreenshot:) forControlEvents:UIControlEventPrimaryActionTriggered];
		[NSLayoutConstraint activateConstraints:@[
												  [_takeScreenshot.widthAnchor constraintEqualToConstant:buttonWidth],
												  [_takeScreenshot.heightAnchor constraintEqualToConstant:buttonWidth],
												  ]];
		
		_settings = [_DTXCaptureControlButton buttonWithType:UIButtonTypeSystem];
		[_settings setImage:[UIImage systemImageNamed:@"gear" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17]] forState:UIControlStateNormal];
		[_settings addTarget:self action:@selector(settings:) forControlEvents:UIControlEventPrimaryActionTriggered];
		[NSLayoutConstraint activateConstraints:@[
												  [_settings.widthAnchor constraintEqualToConstant:buttonWidth],
												  [_settings.heightAnchor constraintEqualToConstant:buttonWidth],
												  ]];
		
		_xyRecord = [_DTXCaptureControlButton buttonWithType:UIButtonTypeSystem];
		_xyRecord.toggled = NSUserDefaults.standardUserDefaults.dtx_attemptXYRecording;
		[_xyRecord setImage:[UIImage systemImageNamed:@"hand.draw.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17]] forState:UIControlStateSelected];
		[_xyRecord setImage:[UIImage systemImageNamed:@"hand.point.right.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17]] forState:UIControlStateNormal];
		[_xyRecord setImageTransform:CGAffineTransformMakeRotation(-M_PI_2) forState:UIControlStateNormal];
		[_xyRecord addTarget:self action:@selector(toggleXYRecording:) forControlEvents:UIControlEventPrimaryActionTriggered];
		[NSLayoutConstraint activateConstraints:@[
												  [_xyRecord.widthAnchor constraintEqualToConstant:buttonWidth],
												  [_xyRecord.heightAnchor constraintEqualToConstant:buttonWidth],
												  ]];
		
		_actionButtonsStackView = [[UIStackView alloc] initWithArrangedSubviews:@[_takeScreenshot, _xyRecord, _settings]];
		_actionButtonsStackView.translatesAutoresizingMaskIntoConstraints = NO;
		_actionButtonsStackView.axis = UILayoutConstraintAxisHorizontal;
		_actionButtonsStackView.distribution = UIStackViewDistributionEqualSpacing;
		_actionButtonsStackView.spacing = UIStackViewSpacingUseSystem;
		
		[_wrapperView addSubview:_actionButtonsStackView];
		
		
		_stopRecording = [_DTXCaptureControlButton buttonWithType:UIButtonTypeSystem];
		[_stopRecording setImage:[UIImage systemImageNamed:@"stop.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20]] forState:UIControlStateNormal];
		[_stopRecording addTarget:self action:@selector(stopRecording:) forControlEvents:UIControlEventPrimaryActionTriggered];
		[NSLayoutConstraint activateConstraints:@[
												  [_stopRecording.widthAnchor constraintEqualToConstant:buttonWidth],
												  [_stopRecording.heightAnchor constraintEqualToConstant:buttonWidth],
												  ]];
		
		[_wrapperView addSubview:_stopRecording];
		
		[NSLayoutConstraint activateConstraints:@[
												  constraint,
												  [_wrapperView.topAnchor constraintGreaterThanOrEqualToAnchor:self.rootViewController.view.topAnchor],
												  [_wrapperView.centerXAnchor constraintEqualToAnchor:self.rootViewController.view.centerXAnchor],
												  [_wrapperView.heightAnchor constraintEqualToConstant:buttonWidth * 1.2222222222],
												  
												  [_actionButtonsStackView.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:_wrapperView.leadingAnchor multiplier:1.0],
												  [_wrapperView.trailingAnchor constraintEqualToSystemSpacingAfterAnchor:_stopRecording.trailingAnchor multiplier:1.0],
												  
												  [_stopRecording.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:_actionButtonsStackView.trailingAnchor multiplier:1.0],
												  [_actionButtonsStackView.centerYAnchor constraintEqualToAnchor:_wrapperView.centerYAnchor],
												  
												  [_stopRecording.centerYAnchor constraintEqualToAnchor:_wrapperView.centerYAnchor],
												  ]];
		
		self.alpha = 0.0;
		
		self.windowLevel = UIWindowLevelStatusBar;
		self.hidden = NO;
		self.windowScene = [UIWindowScene _keyWindowScene];
		
		_stopRecording.tintColor = UIColor.whiteColor;
		_stopRecording.backgroundColor = UIColor.systemRedColor;
		[self traitCollectionDidChange:nil];
		
		[UIView animateWithDuration:0.75 delay:0.0 usingSpringWithDamping:500 initialSpringVelocity:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
			self.alpha = 1.0;
		} completion:nil];

//		[UIView animateWithDuration:0.6 delay:0.15 usingSpringWithDamping:500 initialSpringVelocity:0.0 options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
//			[_wrapperView layoutIfNeeded];
//		} completion:nil];
	}
	
	return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIView* test = [super hitTest:point withEvent:event];
	return test == self || test == self.rootViewController.view ? nil : test;
}

- (void)settings:(UIButton*)button
{
	
}

- (void)toggleXYRecording:(_DTXCaptureControlButton*)button
{
	NSUserDefaults.standardUserDefaults.dtx_attemptXYRecording = !NSUserDefaults.standardUserDefaults.dtx_attemptXYRecording;
	button.toggled = !button.toggled;
}

- (void)takeScreenshot:(UIButton*)button
{
	_wrapperView.alpha = 0.0;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			UIView* snapshotView = [self.screen snapshotViewAfterScreenUpdates:YES];
			snapshotView.clipsToBounds = YES;
			snapshotView.layer.borderWidth = 20.0;
			snapshotView.layer.borderColor = UIColor.labelColor.CGColor;
			snapshotView.layer.cornerRadius = 30.0;
			
			UIView* transitionView = [[UIView alloc] initWithFrame:self.bounds];
			transitionView.userInteractionEnabled = NO;
			transitionView.backgroundColor = UIColor.clearColor;
			
			[self addSubview:transitionView];
			[self sendSubviewToBack:transitionView];
			
			[DTXUIInteractionRecorder addTakeScreenshot];
			[UIView animateWithDuration:0.2 delay:0.0 usingSpringWithDamping:500.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
				transitionView.backgroundColor = UIColor.whiteColor;
			} completion:^(BOOL finished) {
				AudioServicesPlayAlertSoundWithCompletion((SystemSoundID)1108, nil);
				
				[self addSubview:snapshotView];
				[self sendSubviewToBack:snapshotView];
				
				[UIView animateWithDuration:0.8 delay:0.0 usingSpringWithDamping:500.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
					snapshotView.transform = CGAffineTransformMakeScale(SCREEN_PERCENT, SCREEN_PERCENT);
					snapshotView.center = CGPointMake(MAX(20, self.safeAreaInsets.left) + self.bounds.size.width * (SCREEN_PERCENT / 2.0), self.bounds.size.height * (1.0 - SCREEN_PERCENT / 2.0) - MAX(20, self.safeAreaInsets.bottom));
				} completion:^(BOOL finished) {
					[UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:500.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
						snapshotView.center = CGPointMake(- self.bounds.size.width * SCREEN_PERCENT, snapshotView.center.y);
					} completion:^(BOOL finished) {
						[snapshotView removeFromSuperview];
						
						_wrapperView.alpha = 0.0;
						
						[UIView animateWithDuration:0.5 delay:0.1 usingSpringWithDamping:500.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
							_wrapperView.alpha = 0.75;
						} completion:nil];
					}];
				}];
				
				[UIView animateWithDuration:0.7 delay:0.0 usingSpringWithDamping:500.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
					transitionView.backgroundColor = UIColor.clearColor;
				} completion:^(BOOL finished) {
					[transitionView removeFromSuperview];
				}];
			}];
		});
	});
}

- (void)stopRecording:(UIButton*)button
{
	[UIView performSystemAnimation:UISystemAnimationDelete onViews:@[self] options:0 animations:nil completion:^(BOOL finished) {
		[DTXUIInteractionRecorder endRecording];
	}];
}

@end
