//
//  DTXViewSelectionWindow.m
//  DetoxRecorder
//
//  Created by Leo Natan on 12/6/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXExpectationBuilderWindow.h"
#import "DTXUIInteractionRecorder.h"
#import "DTXElementPickerController.h"

@interface UIWindowScene ()

+ (instancetype)_keyWindowScene;
@property (readonly, nonatomic) UIWindow *_keyWindow;

@end

@interface UIView ()

@property (nonatomic, getter=isHiddenOrHasHiddenAncestor) BOOL hiddenOrHasHiddenAncestor;

@end

@interface UIWindow ()

- (void)_makeKeyWindowIgnoringOldKeyWindow:(BOOL)arg1;

@end

@interface UIView (ViewSelection) @end
@implementation UIView (ViewSelection)

- (UIView*)_dtxrec_customPickTest:(CGPoint)point withEvent:(UIEvent*)event
{
	if(self.isHiddenOrHasHiddenAncestor == YES)
	{
		return nil;
	}
	
	if(self.alpha == 0.0)
	{
		return nil;
	}
	
	if([self pointInside:point withEvent:event] == NO)
	{
		return nil;
	}
	
	UIView* rv = self;
	
	if([rv isKindOfClass:UIControl.class] ||
	   [rv isKindOfClass:UITextView.class] ||
	   [rv isKindOfClass:NSClassFromString(@"WKWebView")] ||
	   [rv isKindOfClass:NSClassFromString(@"MKMapView")])
	{
		return rv;
	}
	
	//Front-most views get priority
	for (__kindof UIView * _Nonnull subview in self.subviews.reverseObjectEnumerator) {
		CGPoint localPoint = [self convertPoint:point toView:subview];
		UIView* candidate = [subview _dtxrec_customPickTest:localPoint withEvent:event];
		
		if(candidate == nil)
		{
			continue;
		}
		
		rv = candidate;
		break;
	}
	
	return rv;
}

@end

@interface DTXExpectationBuilderWindow () <DTXElementPickerControllerDelegate>

@end

@implementation DTXExpectationBuilderWindow
{
	DTXCaptureControlWindow* _captureControlWindow;
	BOOL _pickingVisually;
	UIVisualEffectView* _backgroundView;
	UIButton* _closeButton;
	
	DTXElementPickerController* _navigationController;
	
	BOOL _finished;
}

- (instancetype)initWithCaptureControlWindow:(DTXCaptureControlWindow*)captureControlWindow
{
	self = [super initWithFrame:captureControlWindow.screen.bounds];
	
	if(self)
	{
		_backgroundView = [[UIVisualEffectView alloc] initWithEffect:nil];
		_backgroundView.frame = self.bounds;
		_backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:_backgroundView];
		
		_closeButton = [UIButton buttonWithType:UIButtonTypeClose];
		_closeButton.translatesAutoresizingMaskIntoConstraints = NO;
		[_closeButton addTarget:self action:@selector(_close:) forControlEvents:UIControlEventPrimaryActionTriggered];
		[self addSubview:_closeButton];
		
//		static const CGFloat notchWidth = 209.0;
		
		[NSLayoutConstraint activateConstraints:@[
			[_closeButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:4],
			[_closeButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:30],
		]];
		
		_navigationController = [DTXElementPickerController new];
		_navigationController.delegate = self;
		self.rootViewController = _navigationController;
		
		self.windowScene = captureControlWindow.windowScene;
		_captureControlWindow = captureControlWindow;
	}
	
	return self;
}

- (void)setAlpha:(CGFloat)alpha
{
	for (UIView* subview in self.subviews) {
		if(subview == _backgroundView || subview == _closeButton)
		{
			continue;
		}
		
		subview.alpha = alpha;
	}
}

- (void)makeKeyAndVisible
{
	[super makeKeyAndVisible];
	
	self.alpha = 0.0;
	
	[UIView animateKeyframesWithDuration:0.25 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
			_backgroundView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial];
		}];
		[UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^{
			self.alpha = 1.0;
		}];
	} completion:nil];
}

- (void)_close:(UIButton*)sender
{
	[UIView animateKeyframesWithDuration:0.25 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^{
			self.alpha = 0.0;
		}];
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
			_backgroundView.effect = nil;
		}];
	} completion:^(BOOL finished) {
		[self.delegate expectationBuilderWindowDidEnd:self];
	}];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	[self bringSubviewToFront:_closeButton];
}

- (void)_makeKeyWindowIgnoringOldKeyWindow:(BOOL)arg1
{
	if(_finished)
	{
		[self.appWindow makeKeyWindow];
		
		return;
	}
	
	[super _makeKeyWindowIgnoringOldKeyWindow:arg1];
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
	if(_pickingVisually)
	{
		id rv = [self.appWindow _dtxrec_customPickTest:point withEvent:event];
		
		[_navigationController visualElementPickerDidSelectElement:rv];
		
		_pickingVisually = NO;
		[UIView animateKeyframesWithDuration:0.25 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
			[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
				_backgroundView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial];
			}];
			[UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^{
				self.alpha = 1.0;
			}];
		} completion:nil];
		
		return self;
	}
	
	return [super hitTest:point withEvent:event];
}

- (void)elementPickerControllerDidStartVisualPicker:(DTXElementPickerController*)elementPickerController
{
	[UIView animateKeyframesWithDuration:0.25 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^{
			self.alpha = 0.0;
		}];
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
			_backgroundView.effect = nil;
		}];
	} completion:^(BOOL finished) {
		_pickingVisually = YES;
	}];
}

@end
