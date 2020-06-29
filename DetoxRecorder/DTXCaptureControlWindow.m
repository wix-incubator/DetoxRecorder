//
//  DTXCaptureControlWindow.m
//  UI
//
//  Created by Leo Natan (Wix) on 4/11/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "DTXCaptureControlWindow.h"
#import "DTXUIInteractionRecorder.h"
#import "DTXRecSettingsViewController.h"
#import "NSUserDefaults+RecorderUtils.h"
@import AudioToolbox;

@interface UIWindowScene ()

+ (instancetype)_keyWindowScene;
@property(readonly, nonatomic) UIWindow *_keyWindow;

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
		if (@available(iOS 13.4, *))
		{
			self.pointerInteractionEnabled = YES;
		}
		
		[NSLayoutConstraint activateConstraints:@[
			[self.widthAnchor constraintEqualToConstant:buttonWidth],
			[self.heightAnchor constraintEqualToConstant:buttonWidth],
		]];
		
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

@interface DTXCaptureControlWindow () <UIAdaptivePresentationControllerDelegate> @end

@implementation DTXCaptureControlWindow
{
	UIView* _wrapperView;
	_DTXCaptureControlButton* _stopRecording;
	
	UIStackView* _actionButtonsStackView;
	UIScrollView* _actionButtonsScrollView;
	_DTXCaptureControlButton* _takeScreenshot;
	_DTXCaptureControlButton* _xyRecord;
	_DTXCaptureControlButton* _settings;
	_DTXCaptureControlButton* _addComment;
	
	NSLayoutConstraint* _topConstraint;
	
	__weak UIWindow* _prevKeyWindow;
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
		_wrapperView.alpha = 0.85;
		
		[self.rootViewController.view addSubview:_wrapperView];
		
		_topConstraint = [_wrapperView.topAnchor constraintEqualToAnchor:self.rootViewController.view.safeAreaLayoutGuide.topAnchor];
		_topConstraint.priority = UILayoutPriorityRequired;
		[self _updateTopConstraint];
		
		_takeScreenshot = [_DTXCaptureControlButton buttonWithType:UIButtonTypeSystem];
		[_takeScreenshot setImage:[UIImage systemImageNamed:@"camera.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17]] forState:UIControlStateNormal];
		[_takeScreenshot addTarget:self action:@selector(takeScreenshot:) forControlEvents:UIControlEventPrimaryActionTriggered];
	
		UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(takeScreenshotLongPress:)];
		[_takeScreenshot addGestureRecognizer:longPress];
		
		_settings = [_DTXCaptureControlButton buttonWithType:UIButtonTypeSystem];
		
		NSString* gear = @"gear";
		if(@available(iOS 14.0, *))
		{
			gear = @"gearshape.fill";
		}
		
		[_settings setImage:[UIImage systemImageNamed:gear withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17]] forState:UIControlStateNormal];
		[_settings addTarget:self action:@selector(settings:) forControlEvents:UIControlEventPrimaryActionTriggered];
		
		_xyRecord = [_DTXCaptureControlButton buttonWithType:UIButtonTypeSystem];
		[NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:NSStringFromSelector(@selector(dtxrec_attemptXYRecording)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];
		
		NSString* preciseTap = @"hand.draw.fill";
		NSString* normalTap = @"hand.point.right.fill";
		if(@available(iOS 14.0, *))
		{
			preciseTap = @"hand.point.up.braille.fill";
			normalTap = @"hand.tap.fill";
		}
		
		[_xyRecord setImage:[UIImage systemImageNamed:preciseTap withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17]] forState:UIControlStateSelected];
		[_xyRecord setImage:[UIImage systemImageNamed:normalTap withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17]] forState:UIControlStateNormal];
		if_unavailable(iOS 14.0, *)
		{
			[_xyRecord setImageTransform:CGAffineTransformMakeRotation(-M_PI_2) forState:UIControlStateNormal];
		}
		[_xyRecord addTarget:self action:@selector(toggleXYRecording:) forControlEvents:UIControlEventPrimaryActionTriggered];
		
		_addComment = [_DTXCaptureControlButton buttonWithType:UIButtonTypeSystem];
		[_addComment setImage:[UIImage systemImageNamed:@"plus.bubble.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17]] forState:UIControlStateNormal];
		[_addComment addTarget:self action:@selector(addComment:) forControlEvents:UIControlEventPrimaryActionTriggered];
		
		_actionButtonsStackView = [[UIStackView alloc] initWithArrangedSubviews:@[_takeScreenshot, _addComment, _xyRecord, _settings]];
		_actionButtonsStackView.translatesAutoresizingMaskIntoConstraints = NO;
		_actionButtonsStackView.axis = UILayoutConstraintAxisHorizontal;
		_actionButtonsStackView.distribution = UIStackViewDistributionEqualSpacing;
		_actionButtonsStackView.spacing = UIStackViewSpacingUseSystem;
		
		[_wrapperView addSubview:_actionButtonsStackView];
		
		
		_stopRecording = [_DTXCaptureControlButton buttonWithType:UIButtonTypeSystem];
		[_stopRecording setImage:[UIImage systemImageNamed:@"stop.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20]] forState:UIControlStateNormal];
		[_stopRecording addTarget:self action:@selector(stopRecording:) forControlEvents:UIControlEventPrimaryActionTriggered];
		
		[_wrapperView addSubview:_stopRecording];
		
		[NSLayoutConstraint activateConstraints:@[
												  _topConstraint,
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
	}
	
	return self;
}

- (void)makeKeyWindow
{
	if(self.isKeyWindow)
	{
		return;
	}
	
	_prevKeyWindow = self.windowScene._keyWindow;
	
	[super makeKeyWindow];
}

- (void)_restoreKeyWindow
{
	[_prevKeyWindow makeKeyWindow];
	_prevKeyWindow = nil;
}

- (void)becomeKeyWindow
{
	[super becomeKeyWindow];
}

- (void)resignKeyWindow
{
	[super resignKeyWindow];
}

- (void)_updateTopConstraint
{
	_topConstraint.constant = self.safeAreaInsets.top < 30 ? 0 : buttonWidth * -0.2722222222;
	[self layoutIfNeeded];
}

- (void)safeAreaInsetsDidChange
{
	[self _updateTopConstraint];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	_xyRecord.toggled = NSUserDefaults.standardUserDefaults.dtxrec_attemptXYRecording;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIView* test = [super hitTest:point withEvent:event];
	return test == self || test == self.rootViewController.view ? nil : test;
}

- (void)settings:(UIButton*)button
{
	auto settingsController = [[DTXRecSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	auto navigationController = [[UINavigationController alloc] initWithRootViewController:settingsController];
	navigationController.presentationController.delegate = self;
	
	[self.rootViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)toggleXYRecording:(_DTXCaptureControlButton*)button
{
	NSUserDefaults.standardUserDefaults.dtxrec_attemptXYRecording = !NSUserDefaults.standardUserDefaults.dtxrec_attemptXYRecording;
}

- (void)takeScreenshot:(UIButton*)button
{
	[DTXUIInteractionRecorder addTakeScreenshot];
}

static __weak UIAlertAction* __okAction;

- (void)_alertControllerTextFieldTextDidChange:(UITextField*)textField
{
	if(textField.text.length > 0)
	{
		__okAction.enabled = YES;
	}
	else
	{
		__okAction.enabled = NO;
	}
}

- (void)takeScreenshotLongPress:(UILongPressGestureRecognizer*)lgr
{
	if(lgr.state != UIGestureRecognizerStateBegan)
	{
		return;
	}
	
	UIAlertController* screenshot = [UIAlertController alertControllerWithTitle:@"Screenshot Name" message:nil preferredStyle:UIAlertControllerStyleAlert];
	[screenshot addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
		textField.placeholder = @"Name";
		[textField addTarget:self action:@selector(_alertControllerTextFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
		[self makeKeyWindow];
		[textField becomeFirstResponder];
	}];
	
	UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Take Screenshot" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[DTXUIInteractionRecorder addTakeScreenshotWithName:screenshot.textFields.firstObject.text];
		[self _restoreKeyWindow];
		
	}];
	okAction.enabled = NO;
	
	[screenshot addAction:okAction];
	[screenshot addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		[self _restoreKeyWindow];
	}]];
	
	[self.rootViewController presentViewController:screenshot animated:YES completion:^{
		[screenshot.textFields.firstObject becomeFirstResponder];
	}];
	
	__okAction = okAction;
}

- (void)addComment:(UIButton*)button
{
	UIAlertController* comment = [UIAlertController alertControllerWithTitle:@"Code Comment" message:nil preferredStyle:UIAlertControllerStyleAlert];
	[comment addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
		textField.placeholder = @"Single Line Comment";
		[textField addTarget:self action:@selector(_alertControllerTextFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
		[self makeKeyWindow];
		[textField becomeFirstResponder];
	}];
	
	UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Add Comment" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[DTXUIInteractionRecorder addCodeComment:comment.textFields.firstObject.text];
		[self _restoreKeyWindow];
		
	}];
	okAction.enabled = NO;
	
	[comment addAction:okAction];
	[comment addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		[self _restoreKeyWindow];
	}]];
	
	[self.rootViewController presentViewController:comment animated:YES completion:^{
		[comment.textFields.firstObject becomeFirstResponder];
	}];
	
	__okAction = okAction;
}

- (void)visualizeShakeDevice
{
	if(NSUserDefaults.standardUserDefaults.dtxrec_disableAnimations)
	{
		return;
	}

	[UIView animateKeyframesWithDuration:0.25 delay:0.0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.25 animations:^{
			CGRect frame = self.frame;
			frame.origin.y -= 20;
			self.frame = frame;
		}];
		[UIView addKeyframeWithRelativeStartTime:0.25 relativeDuration:0.25 animations:^{
			CGRect frame = self.frame;
			frame.origin.y += 40;
			self.frame = frame;
		}];
		[UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.25 animations:^{
			CGRect frame = self.frame;
			frame.origin.y -= 50;
			self.frame = frame;
		}];
		[UIView addKeyframeWithRelativeStartTime:0.75 relativeDuration:0.25 animations:^{
			CGRect frame = self.frame;
			frame.origin.y += 30;
			self.frame = frame;
		}];
	} completion:nil];
}

- (void)_shakeView:(UIView*)view
{
	[UIView animateKeyframesWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent | UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.2 animations:^{
			view.transform = CGAffineTransformMakeRotation(M_PI / 6);
		}];
		[UIView addKeyframeWithRelativeStartTime:0.2 relativeDuration:0.2 animations:^{
			view.transform = CGAffineTransformMakeRotation(- M_PI / 6);
		}];
		[UIView addKeyframeWithRelativeStartTime:0.4 relativeDuration:0.2 animations:^{
			view.transform = CGAffineTransformMakeRotation(M_PI / 6);
		}];
		[UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.2 animations:^{
			view.transform = CGAffineTransformMakeRotation(- M_PI / 6);
		}];
		[UIView addKeyframeWithRelativeStartTime:0.8 relativeDuration:0.2 animations:^{
			view.transform = CGAffineTransformIdentity;
		}];
	} completion:nil];
}

- (void)visualizeAddComment:(NSString*)comment
{
	[self _shakeView:_addComment];
}

- (void)visualizeTakeScreenshotWithName:(NSString*)name
{
	if(NSUserDefaults.standardUserDefaults.dtxrec_disableAnimations)
	{
		[self _shakeView:_takeScreenshot];
		
		UIView* transitionView = [[UIView alloc] initWithFrame:self.bounds];
		transitionView.userInteractionEnabled = NO;
		transitionView.backgroundColor = UIColor.clearColor;

		[self addSubview:transitionView];
		[self sendSubviewToBack:transitionView];

		[UIView animateWithDuration:0.1 delay:0.0 usingSpringWithDamping:500.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
			transitionView.backgroundColor = UIColor.whiteColor;
		} completion:^(BOOL finished) {
			AudioServicesPlaySystemSoundWithCompletion((SystemSoundID)1108, nil);

			[UIView animateWithDuration:0.35 delay:0.0 usingSpringWithDamping:500.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
				transitionView.backgroundColor = UIColor.clearColor;
			} completion:^(BOOL finished) {
				[transitionView removeFromSuperview];
			}];
		}];
		
		return;
	}
	
	_wrapperView.alpha = 0.0;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			UIView* _snapshotView = [self.screen snapshotViewAfterScreenUpdates:YES];
			
			UIView* snapshotView = [UIView new];
			snapshotView.clipsToBounds = YES;
			snapshotView.layer.borderWidth = 20.0;
			snapshotView.layer.borderColor = UIColor.labelColor.CGColor;
			snapshotView.layer.cornerRadius = 30.0;
			snapshotView.frame = self.bounds;
			[snapshotView addSubview:_snapshotView];
			
			UIView* transitionView = [[UIView alloc] initWithFrame:self.bounds];
			transitionView.userInteractionEnabled = NO;
			transitionView.backgroundColor = UIColor.clearColor;
			
			[self addSubview:transitionView];
			[self sendSubviewToBack:transitionView];
			
			[UIView animateWithDuration:0.1 delay:0.0 usingSpringWithDamping:500.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
				transitionView.backgroundColor = UIColor.whiteColor;
			} completion:^(BOOL finished) {
				AudioServicesPlayAlertSoundWithCompletion((SystemSoundID)1108, nil);
				
				[self addSubview:snapshotView];
				[self sendSubviewToBack:snapshotView];
				
				[UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:500.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
					snapshotView.transform = CGAffineTransformMakeScale(SCREEN_PERCENT, SCREEN_PERCENT);
					snapshotView.center = CGPointMake(MAX(20, self.safeAreaInsets.left) + self.bounds.size.width * (SCREEN_PERCENT / 2.0), self.bounds.size.height * (1.0 - SCREEN_PERCENT / 2.0) - MAX(20, self.safeAreaInsets.bottom));
				} completion:^(BOOL finished) {
					[UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:500.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
						snapshotView.center = CGPointMake(- self.bounds.size.width * SCREEN_PERCENT, snapshotView.center.y);
					} completion:^(BOOL finished) {
						[snapshotView removeFromSuperview];
						
						_wrapperView.alpha = 0.0;
						
						[UIView animateWithDuration:0.25 delay:0.1 usingSpringWithDamping:500.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
							_wrapperView.alpha = 0.75;
						} completion:nil];
					}];
				}];
				
				[UIView animateWithDuration:0.35 delay:0.0 usingSpringWithDamping:500.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
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

- (void)dealloc
{
	[NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:NSStringFromSelector(@selector(dtxrec_attemptXYRecording))];
}

#pragma mark UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
	if(traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact)
	{
		return UIModalPresentationOverFullScreen;
	}
	else
	{
		return UIModalPresentationFormSheet;
	}
}

@end
