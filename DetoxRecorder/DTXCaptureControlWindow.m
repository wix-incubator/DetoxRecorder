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

@interface DTXCaptureControlWindow () <UIPopoverPresentationControllerDelegate> @end

@implementation DTXCaptureControlWindow
{
	UIView* _wrapperView;
	UIVisualEffectView* _backgroundView;
	_DTXCaptureControlButton* _stopRecording;
	
	UIVisualEffectView* _chevronEffectView;
	UIButton* _chevronButton;
	UIButton* _openButton;
	
	UIStackView* _actionButtonsStackView;
	UIScrollView* _actionButtonsScrollView;
	_DTXCaptureControlButton* _takeScreenshot;
	_DTXCaptureControlButton* _xyRecord;
	_DTXCaptureControlButton* _settings;
	_DTXCaptureControlButton* _addComment;
	
	NSLayoutConstraint* _topConstraint;
	NSLayoutConstraint* _widthConstraint;
	NSLayoutConstraint* _leadingConstraint;
	NSLayoutConstraint* _trailingConstraint;
	
	__weak UIWindow* _prevKeyWindow;
	
#if DEBUG
	BOOL _introAnimationFinished;
	BOOL _needsArtworkGeneration;
#endif
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
	switch (self.traitCollection.userInterfaceStyle)
	{
		default:
		case UIUserInterfaceStyleLight:
			_backgroundView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
			break;
		case UIUserInterfaceStyleDark:
			_backgroundView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight];
			break;
	}
	
	_chevronEffectView.effect = [UIVibrancyEffect effectForBlurEffect:(id)_backgroundView.effect style:UIVibrancyEffectStyleLabel];
}

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if(self)
	{
		self.rootViewController = [UIViewController new];
	}
	
	return self;
}

- (void)appear
{
	_backgroundView = [UIVisualEffectView new];
	_backgroundView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
	_backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	
	_chevronEffectView = [UIVisualEffectView new];
	_chevronEffectView.effect = [UIVibrancyEffect effectForBlurEffect:(id)_backgroundView.effect style:UIVibrancyEffectStyleLabel];
	_chevronEffectView.translatesAutoresizingMaskIntoConstraints = NO;
	
	_chevronButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[_chevronButton setImage:[UIImage systemImageNamed:@"chevron.compact.right" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:40]] forState:UIControlStateNormal];
	_chevronButton.transform = CGAffineTransformMakeScale(1.0, 0.7);
	_chevronButton.translatesAutoresizingMaskIntoConstraints = NO;
	[_chevronButton addTarget:self action:@selector(_minimizeBar:) forControlEvents:UIControlEventPrimaryActionTriggered];
	
	_openButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[_openButton setImage:[UIImage systemImageNamed:@"chevron.compact.left" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:40]] forState:UIControlStateNormal];
	_openButton.transform = CGAffineTransformMakeScale(1.0, 0.7);
	_openButton.translatesAutoresizingMaskIntoConstraints = NO;
	[_openButton addTarget:self action:@selector(_expandBar:) forControlEvents:UIControlEventPrimaryActionTriggered];
	_openButton.alpha = 0.0;
	
	[_chevronEffectView.contentView addSubview:_chevronButton];
	[_chevronEffectView.contentView addSubview:_openButton];
	[_backgroundView.contentView addSubview:_chevronEffectView];
	
	[NSLayoutConstraint activateConstraints:@[
		[_chevronEffectView.topAnchor constraintEqualToAnchor:_chevronButton.topAnchor],
		[_chevronEffectView.bottomAnchor constraintEqualToAnchor:_chevronButton.bottomAnchor],
		[_chevronEffectView.leadingAnchor constraintEqualToAnchor:_chevronButton.leadingAnchor],
		[_chevronEffectView.trailingAnchor constraintEqualToAnchor:_chevronButton.trailingAnchor],
		
		[_chevronEffectView.topAnchor constraintEqualToAnchor:_openButton.topAnchor],
		[_chevronEffectView.bottomAnchor constraintEqualToAnchor:_openButton.bottomAnchor],
		[_chevronEffectView.leadingAnchor constraintEqualToAnchor:_openButton.leadingAnchor],
		[_chevronEffectView.trailingAnchor constraintEqualToAnchor:_openButton.trailingAnchor],
		
		[_chevronEffectView.leadingAnchor constraintEqualToAnchor:_backgroundView.leadingAnchor constant:12],
		[_chevronEffectView.centerYAnchor constraintEqualToAnchor:_backgroundView.centerYAnchor],
	]];
	
	_wrapperView = [UIView new];
	_wrapperView.translatesAutoresizingMaskIntoConstraints = NO;
	_wrapperView.clipsToBounds = YES;
	
	_wrapperView.layer.cornerRadius = (buttonWidth + 8) / 2;
	
	[self.rootViewController.view addSubview:_wrapperView];
	
	_topConstraint = [_wrapperView.topAnchor constraintEqualToAnchor:self.rootViewController.view.safeAreaLayoutGuide.topAnchor];
	_topConstraint.priority = UILayoutPriorityRequired;
	[self _updateTopConstraint];
	
	UIImageSymbolConfiguration* buttonConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:17];
	
	_takeScreenshot = [_DTXCaptureControlButton buttonWithType:UIButtonTypeSystem];
	[_takeScreenshot setImage:[UIImage systemImageNamed:@"camera.fill" withConfiguration:buttonConfiguration] forState:UIControlStateNormal];
	[_takeScreenshot addTarget:self action:@selector(takeScreenshot:) forControlEvents:UIControlEventPrimaryActionTriggered];
	
	UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(takeScreenshotLongPress:)];
	[_takeScreenshot addGestureRecognizer:longPress];
	
	_settings = [_DTXCaptureControlButton buttonWithType:UIButtonTypeSystem];
	
	NSString* gear = @"gear";
	if(@available(iOS 14.0, *))
	{
		gear = @"gearshape.fill";
	}
	
	[_settings setImage:[UIImage systemImageNamed:gear withConfiguration:buttonConfiguration] forState:UIControlStateNormal];
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
	
	[_xyRecord setImage:[UIImage systemImageNamed:preciseTap withConfiguration:buttonConfiguration] forState:UIControlStateSelected];
	[_xyRecord setImage:[UIImage systemImageNamed:normalTap withConfiguration:buttonConfiguration] forState:UIControlStateNormal];
	if_unavailable(iOS 14.0, *)
	{
		[_xyRecord setImageTransform:CGAffineTransformMakeRotation(-M_PI_2) forState:UIControlStateNormal];
	}
	[_xyRecord addTarget:self action:@selector(toggleXYRecording:) forControlEvents:UIControlEventPrimaryActionTriggered];
	
	_addComment = [_DTXCaptureControlButton buttonWithType:UIButtonTypeSystem];
	[_addComment setImage:[UIImage systemImageNamed:@"plus.bubble.fill" withConfiguration:buttonConfiguration] forState:UIControlStateNormal];
	[_addComment addTarget:self action:@selector(addComment:) forControlEvents:UIControlEventPrimaryActionTriggered];
	
	_stopRecording = [_DTXCaptureControlButton buttonWithType:UIButtonTypeSystem];
	[_stopRecording setImage:[UIImage systemImageNamed:@"stop.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20]] forState:UIControlStateNormal];
	[_stopRecording addTarget:self action:@selector(stopRecording:) forControlEvents:UIControlEventPrimaryActionTriggered];
	
	_actionButtonsStackView = [[UIStackView alloc] initWithArrangedSubviews:@[_takeScreenshot, _addComment, _xyRecord, _settings]];
	_actionButtonsStackView.translatesAutoresizingMaskIntoConstraints = NO;
	_actionButtonsStackView.axis = UILayoutConstraintAxisHorizontal;
	_actionButtonsStackView.distribution = UIStackViewDistributionEqualSpacing;
	_actionButtonsStackView.spacing = UIStackViewSpacingUseSystem;
	
	[_wrapperView addSubview:_backgroundView];
	[_wrapperView addSubview:_actionButtonsStackView];
	[_wrapperView addSubview:_stopRecording];
	
	_widthConstraint = [_wrapperView.widthAnchor constraintEqualToConstant:buttonWidth + 40];
	_widthConstraint.active = NO;
	
	_leadingConstraint = [_actionButtonsStackView.leadingAnchor constraintEqualToAnchor:_wrapperView.leadingAnchor constant:40.0];
	_trailingConstraint = [_stopRecording.leadingAnchor constraintEqualToAnchor:_actionButtonsStackView.trailingAnchor constant:8.0];
	
	[NSLayoutConstraint activateConstraints:@[
		[_wrapperView.topAnchor constraintEqualToAnchor:_backgroundView.topAnchor],
		[_wrapperView.bottomAnchor constraintEqualToAnchor:_backgroundView.bottomAnchor],
		[_wrapperView.leadingAnchor constraintEqualToAnchor:_backgroundView.leadingAnchor],
		[_wrapperView.trailingAnchor constraintEqualToAnchor:_backgroundView.trailingAnchor],
		
		_topConstraint,
		[_wrapperView.centerXAnchor constraintEqualToAnchor:self.rootViewController.view.centerXAnchor],
		[_wrapperView.heightAnchor constraintEqualToConstant:buttonWidth + 8],
		
		_leadingConstraint,
		_trailingConstraint,
		[_wrapperView.trailingAnchor constraintEqualToAnchor:_stopRecording.trailingAnchor constant:4],
		
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
	
	[UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:500 initialSpringVelocity:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent animations:^{
		self.alpha = 1.0;
	} completion:^(BOOL finished) {
#if DEBUG
		_introAnimationFinished = YES;
		if(_needsArtworkGeneration)
		{
			[self _generateArtwork];
			
			return;
		}
#endif
		
		if(NSUserDefaults.standardUserDefaults.dtxrec_recordingBarMinimized == YES)
		{
			[self _minimizeBar:_chevronButton];
		}
	}];
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
	if(self.rootViewController.presentedViewController != nil)
	{
		return [super hitTest:point withEvent:event];
	}
	
	UIView* test = [super hitTest:point withEvent:event];
	return (test == self || test == self.rootViewController.view) ? nil : test;
}

- (void)settings:(UIButton*)button
{
	auto settingsController = [[DTXRecSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	auto navigationController = [[UINavigationController alloc] initWithRootViewController:settingsController];
	navigationController.navigationBar.prefersLargeTitles = NO;
	navigationController.modalPresentationStyle = UIModalPresentationPopover;
	navigationController.popoverPresentationController.sourceView = button;
	navigationController.popoverPresentationController.delegate = self;
	
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

- (void)_minimizeBar:(UIButton*)button
{
	[UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:500.0 initialSpringVelocity:0 options:0 animations:^{
		_leadingConstraint.active = NO;
		_trailingConstraint.active = NO;
		_widthConstraint.active = YES;
		
		[_wrapperView setNeedsUpdateConstraints];
		[_wrapperView layoutIfNeeded];
		
		_actionButtonsStackView.alpha = 0.0;
		_chevronButton.alpha = 0.0;
		_openButton.alpha = 1.0;
	} completion:^(BOOL finished) {
		NSUserDefaults.standardUserDefaults.dtxrec_recordingBarMinimized = YES;
	}];
}

- (void)_expandBar:(UIButton*)button
{
	[UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:500.0 initialSpringVelocity:0 options:0 animations:^{
		_widthConstraint.active = NO;
		_leadingConstraint.active = YES;
		_trailingConstraint.active = YES;
		
		[_wrapperView setNeedsUpdateConstraints];
		[_wrapperView layoutIfNeeded];
		
		_actionButtonsStackView.alpha = 1.0;
		_chevronButton.alpha = 1.0;
		_openButton.alpha = 0.0;
	} completion:^(BOOL finished) {
		NSUserDefaults.standardUserDefaults.dtxrec_recordingBarMinimized = NO;
	}];
}

- (void)dealloc
{
	[NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:NSStringFromSelector(@selector(dtxrec_attemptXYRecording))];
}

#pragma mark UIPopoverPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
	if(traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact)
	{
		return UIModalPresentationFullScreen;
	}
	else
	{
		return UIModalPresentationPopover;
	}
}

#if DEBUG
- (void)_generateArtwork
{
	self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
	
	NSURL* url= [[[NSURL fileURLWithPath:[[NSBundle bundleForClass:self.class] objectForInfoDictionaryKey:@"DTXSourceRoot"]] URLByAppendingPathComponent:@"../Documentation/Resources"] URLByStandardizingPath];
	
	UIGraphicsBeginImageContextWithOptions(_wrapperView.bounds.size, NO, 1.5);
	_wrapperView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.25];
	UIVisualEffect* effect = _backgroundView.effect;
	_backgroundView.effect = nil;
	[_wrapperView drawViewHierarchyInRect:_wrapperView.bounds afterScreenUpdates:YES];
	_wrapperView.backgroundColor = nil;
	_backgroundView.effect = effect;
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	[UIImagePNGRepresentation(image) writeToURL:[url URLByAppendingPathComponent:@"RecordingBar.png"] atomically:YES];
	
	const CGFloat pointSize = 6;
	
	[UIImagePNGRepresentation([[_takeScreenshot imageForState:UIControlStateNormal] imageWithConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pointSize]]) writeToURL:[url URLByAppendingPathComponent:@"ScreenshotButton.png"] atomically:YES];
	[UIImagePNGRepresentation([[_addComment imageForState:UIControlStateNormal] imageWithConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pointSize]]) writeToURL:[url URLByAppendingPathComponent:@"AddCommentButton.png"] atomically:YES];
	[UIImagePNGRepresentation([[_xyRecord imageForState:UIControlStateNormal] imageWithConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pointSize]]) writeToURL:[url URLByAppendingPathComponent:@"TapTypeButton.png"] atomically:YES];
	[UIImagePNGRepresentation([[_settings imageForState:UIControlStateNormal] imageWithConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pointSize]]) writeToURL:[url URLByAppendingPathComponent:@"SettingsButton.png"] atomically:YES];
	[UIImagePNGRepresentation([[_stopRecording imageForState:UIControlStateNormal] imageWithConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pointSize]]) writeToURL:[url URLByAppendingPathComponent:@"StopButton.png"] atomically:YES];
	
	[self settings:_settings];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		CGRect safeBounds = UIEdgeInsetsInsetRect(self.bounds, self.safeAreaInsets);
		CGRect drawBounds = CGRectOffset(self.bounds, 0, -self.safeAreaInsets.top);
		
		UIGraphicsBeginImageContextWithOptions(safeBounds.size, NO, 1.0);
		[self drawViewHierarchyInRect:drawBounds afterScreenUpdates:YES];
		UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		[UIImagePNGRepresentation(image) writeToURL:[url URLByAppendingPathComponent:@"RecordingSettings.png"] atomically:YES];
		
		[self.rootViewController dismissViewControllerAnimated:YES completion:nil];
		
		self.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
	});
}

- (void)generateScreenshotsForDocumentation
{
	if(_introAnimationFinished == YES)
	{
		[self _generateArtwork];
		_needsArtworkGeneration = NO;
		
		return;
	}
	
	_needsArtworkGeneration = YES;
}
#endif

@end

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
