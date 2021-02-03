//
//  DTXUIInteractionRecorder.m
//  UI
//
//  Created by Leo Natan (Wix) on 4/9/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "DTXUIInteractionRecorder-Private.h"
#import "DTXCaptureControlWindow.h"
#import "DTXRecordedAction.h"
#import "DTXAppleInternals.h"
#import "NSUserDefaults+RecorderUtils.h"
#import "NSString+SimulatorSafeTildeExpansion.h"
#import <DTXSocketConnection/DTXSocketConnection.h>

DTX_CREATE_LOG(InteractionController)

#define IGNORE_RECORDING_WINDOW(view) if((id)view.window == (id)captureControlWindow || (id)view.window == (id)captureControlWindow.expectationBuilderWindow) { return; }

@interface _DTXVisualizedView : UIView

@property (nonatomic, strong) NSArray<UIImageView*>* imageViews;

@end
@implementation _DTXVisualizedView @end

@interface DTXUIInteractionRecorder ()

+ (void)netServiceDidResolveAddress:(NSNetService *)sender;
+ (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict;
+ (void)readClosedForSocketConnection:(DTXSocketConnection*)socketConnection;
+ (void)writeClosedForSocketConnection:(DTXSocketConnection*)socketConnection;

@end

@implementation DTXUIInteractionRecorder

static __weak id<DTXUIInteractionRecorderDelegate> delegate;
static BOOL startedByUser;
static NSMutableArray<DTXRecordedAction*>* recordedActions;
static DTXCaptureControlWindow* captureControlWindow;
static UIView* previousTextChangeVisualizer;
static dispatch_block_t _appearanceBlock;

//Socket connection based recording
static NSNetService* _service;
static DTXSocketConnection* _currentConnection;
static dispatch_source_t _pingTimer;

DTX_ALWAYS_INLINE
static void DTXSendCommand(NSDictionary* dict)
{
	NSData* data = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
	
	[_currentConnection sendMessage:data completionHandler:^(NSError * _Nullable error) {
		if(error != nil)
		{
			[DTXUIInteractionRecorder _presentError:error completionHandler:^{
				[DTXUIInteractionRecorder stopRecording];
			}];
		}
	}];
}

DTX_ALWAYS_INLINE
static void DTXAddAction(DTXRecordedAction* action)
{
	[DTXUIInteractionRecorder _enhanceLastScrollEventIfNeededForAction:action];
	
	[recordedActions addObject:action];
	
	DTXSendCommand(@{@"type": @"add", @"command": action.detoxDescription});
	
	if([delegate respondsToSelector:@selector(interactionRecorderDidAddTestCommand:)])
	{
		[delegate interactionRecorderDidAddTestCommand:action.detoxDescription];
	}
}

DTX_ALWAYS_INLINE
static BOOL DTXUpdateAction(BOOL (^updateBlock)(DTXRecordedAction* action, BOOL* remove))
{
	DTXRecordedAction* action = recordedActions.lastObject;
	
	if(action == nil)
	{
		return NO;
	}
	
	BOOL remove = NO;
	BOOL rv = updateBlock(action, &remove);
	
	if(remove)
	{
		[recordedActions removeLastObject];
	}
	
	if(rv == YES)
	{
		if(remove == NO)
		{
			DTXSendCommand(@{@"type": @"update", @"command": action.detoxDescription});
		}
		else
		{
			DTXSendCommand(@{@"type": @"remove"});
		}
	}
	
	if(rv == YES && [delegate respondsToSelector:@selector(interactionRecorderDidUpdateLastTestCommandWithCommand:)])
	{
		[delegate interactionRecorderDidUpdateLastTestCommandWithCommand:remove ? nil : action.detoxDescription];
	}
	
	return rv;
}

+ (void)load
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		if([NSUserDefaults.standardUserDefaults boolForKey:@"DTXRecStartRecording"] == YES)
		{
			[self _startRecordingByUser:NO];
		}
	});
}

+ (id<DTXUIInteractionRecorderDelegate>)delegate
{
	return delegate;
}

+ (void)setDelegate:(id<DTXUIInteractionRecorderDelegate>)_delegate
{
	delegate = _delegate;
}

+ (void)startRecording
{
	[self _startRecordingByUser:YES];
}

+ (void)_presentError:(NSError*)error completionHandler:(dispatch_block_t)handler
{
	if(NSThread.isMainThread == NO)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self _presentError:error completionHandler:handler];
		});
		
		return;
	}
	
	UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"Recording Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
	[errorAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		if(handler) { handler(); }
	}]];
	
	[captureControlWindow.rootViewController presentViewController:errorAlert animated:YES completion:nil];
}

+ (void)_startRecordingByUser:(BOOL)byUser;
{
	if(captureControlWindow != nil)
	{
		return;
	}
	
	startedByUser = byUser;
	
	recordedActions = [NSMutableArray new];
	[DTXRecordedAction resetScreenshotCounter];
	
	captureControlWindow = [[DTXCaptureControlWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
	_appearanceBlock = ^ {
		[captureControlWindow appear];
	};
	
	NSString* serviceName = [NSUserDefaults.standardUserDefaults stringForKey:@"DTXServiceName"];
	if(serviceName != nil)
	{
		_service = [[NSNetService alloc] initWithDomain:@"local" type:@"_detoxrecorder._tcp" name:serviceName];
		[_service scheduleInRunLoop:NSRunLoop.currentRunLoop forMode:NSDefaultRunLoopMode];
		_service.delegate = (id)self;
		[_service resolveWithTimeout:2];
	}
	else
	{
		_appearanceBlock();
		_appearanceBlock = nil;
	}
	
#if DEBUG
	if([NSUserDefaults.standardUserDefaults boolForKey:@"DTXGenerateArtwork"])
	{
		[captureControlWindow generateScreenshotsForDocumentation];
	}
#endif
}

+ (void)_exitIfNeeded
{
	BOOL responds = [delegate respondsToSelector:@selector(interactionRecorderShouldExitApp)];
	if([NSUserDefaults.standardUserDefaults boolForKey:@"DTXRecNoExit"] == NO &&
		((responds == NO && startedByUser == NO) ||
		(responds == YES && [delegate interactionRecorderShouldExitApp] == YES)))
	{
		exit(0);
	}
}

#define IGNORE_IF_WAS_ERROR(x) if(fileError == nil) { x; if(fileError != nil) { dtx_log_error(@"Error writing to output file: %@", fileError.localizedDescription); } }

+ (void)stopRecording
{
	if(_pingTimer != nil)
	{
		dispatch_cancel(_pingTimer);
	}
	_pingTimer = nil;
	
	__block NSError* fileError = nil;
	BOOL delayExit = NO;
	
	NSFileHandle* file = nil;
	if(_currentConnection == nil)
	{
		NSString* testNamePath = [NSUserDefaults.standardUserDefaults stringForKey:@"DTXRecTestOutputPath"];
		NSString* testName = [NSUserDefaults.standardUserDefaults stringForKey:@"DTXRecTestName"] ?: @"My Recorded Test";
	
		NSURL* testOutputURL = [NSURL fileURLWithPath:testNamePath.dtx_stringByExpandingTildeInPath];
		NSURL* directoryURL;
		
		if(testOutputURL.hasDirectoryPath)
		{
			directoryURL = testOutputURL;
			testOutputURL = [testOutputURL URLByAppendingPathComponent:@"recorder_test.js" isDirectory:NO];
		} else {
			directoryURL = [testOutputURL URLByDeletingLastPathComponent];
		}
		
		IGNORE_IF_WAS_ERROR([NSFileManager.defaultManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&fileError]);
		
		if(testOutputURL != nil)
		{
			IGNORE_IF_WAS_ERROR([@"" writeToURL:testOutputURL atomically:YES encoding:NSUTF8StringEncoding error:&fileError]);
			IGNORE_IF_WAS_ERROR(file = [NSFileHandle fileHandleForWritingToURL:testOutputURL error:&fileError]);
		}
		
		NSString* str = [NSString stringWithFormat:@"describe('Recorded suite', () => {\n\tit('%@', async () => {\n", testName];
		IGNORE_IF_WAS_ERROR([file writeData:[str dataUsingEncoding:NSUTF8StringEncoding]]);
	}
	
	NSMutableArray<NSString*>* detoxCommands = nil;
	if([delegate respondsToSelector:@selector(interactionRecorderDidEndRecordingWithTestCommands:)])
	{
		detoxCommands = [NSMutableArray new];
	}
	
	[recordedActions enumerateObjectsUsingBlock:^(DTXRecordedAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString* detoxDescription = obj.detoxDescription;
		
		if(_currentConnection == nil)
		{
			NSString* str = [NSString stringWithFormat:@"\t\t%@\n", detoxDescription];
			IGNORE_IF_WAS_ERROR([file writeData:[str dataUsingEncoding:NSUTF8StringEncoding] error:&fileError]);
		}
		
		[detoxCommands addObject:detoxDescription];
	}];
	
	if(detoxCommands != nil)
	{
		[delegate interactionRecorderDidEndRecordingWithTestCommands:detoxCommands];
	}
	
	if(_currentConnection == nil)
	{
		IGNORE_IF_WAS_ERROR([file writeData:[@"\t})\n});" dataUsingEncoding:NSUTF8StringEncoding] error:&fileError]);
		IGNORE_IF_WAS_ERROR([file closeAndReturnError:&fileError]);
	}
	
	if(_currentConnection != nil)
	{
		DTXSendCommand(@{@"type": @"end"});
		[_currentConnection closeRead];
		[_currentConnection closeWrite];
		_currentConnection = nil;
	}
	
	recordedActions = nil;
	
	dispatch_block_t UICleanupBlock = ^ {
		captureControlWindow.hidden = YES;
		captureControlWindow = nil;
		
		[self _exitIfNeeded];
	};
	
	if(fileError != nil)
	{
		delayExit = YES;
		[self _presentError:fileError completionHandler:UICleanupBlock];
	}
	
	if(delayExit == NO)
	{
		UICleanupBlock();
	}
}

static NSTimeInterval lastRecordedEventTimestamp;
#define IGNORE_IF_FROM_LAST_EVENT if(event != nil && event.timestamp == lastRecordedEventTimestamp) { return; } else { lastRecordedEventTimestamp = event.timestamp; }

+ (_DTXVisualizedView*)_visualizerViewForView:(UIView*)view action:(DTXRecordedAction*)action systemImageNames:(NSArray<NSString*>*)systemImageNames applyConstraints:(BOOL)applyConstraints
{
	NSMutableArray* transforms = [NSMutableArray new];
	NSValue* transform = [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
	
	[systemImageNames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[transforms addObject:transform];
	}];
	
	return [self _visualizerViewForView:view action:action systemImageNames:systemImageNames imageViewTransforms:transforms applyConstraints:applyConstraints];
}

+ (_DTXVisualizedView*)_visualizerViewForView:(UIView*)view action:(DTXRecordedAction*)action systemImageName:(NSString*)systemImageName
{
	return [self _visualizerViewForView:view action:action systemImageNames:@[systemImageName] imageViewTransforms:@[[NSValue valueWithCGAffineTransform:CGAffineTransformIdentity]] applyConstraints:YES];
}

static void _traverseElementMatchersAndFill(DTXRecordedElement* element, BOOL* anyById, BOOL* anyByText, BOOL* anyByLabel, BOOL* anyByClass, BOOL* anyByIndex, BOOL* hasAncestorChain)
{
	if(element == nil)
	{
		return;
	}
	
	*anyByIndex |= element.requiresAtIndex;
	
	[element.matchers enumerateObjectsUsingBlock:^(DTXRecordedElementMatcher * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		*anyById |= (obj.matcherType == DTXRecordedElementMatcherTypeById);
		*anyByText |= (obj.matcherType == DTXRecordedElementMatcherTypeByText);
		*anyByLabel |= (obj.matcherType == DTXRecordedElementMatcherTypeByLabel);
		*anyByClass |= (obj.matcherType == DTXRecordedElementMatcherTypeByType);
	}];
	
	*hasAncestorChain |= (element.ancestorElement != nil);
	
	_traverseElementMatchersAndFill(element.ancestorElement, anyById, anyByText, anyByLabel, anyByClass, anyByIndex, hasAncestorChain);
}

+ (_DTXVisualizedView*)_visualizerViewForView:(UIView*)view action:(DTXRecordedAction*)action systemImageNames:(NSArray<NSString*>*)systemImageNames imageViewTransforms:(NSArray<NSValue* /*CGAffineTransform*/>*)transforms applyConstraints:(BOOL)applyConstraints
{
	if(NSUserDefaults.standardUserDefaults.dtxrec_disableVisualizations)
	{
		return nil;
	}
	
	_DTXVisualizedView* visualizer = [_DTXVisualizedView new];
	
	UIColor* color;
	
	BOOL anyById = NO;
	BOOL anyByText = NO;
	BOOL anyByLabel = NO;
	BOOL anyByClass = NO;
	BOOL anyByIndex = NO;
	BOOL hasAncestorChain = NO;
	
	_traverseElementMatchersAndFill(action.element, &anyById, &anyByText, &anyByLabel, &anyByClass, &anyByIndex, &hasAncestorChain);
	
	if(anyById == YES && anyByIndex == NO)
	{
		color = UIColor.systemGreenColor;
	}
	else if((anyByText == YES || anyByLabel == YES) && anyByClass == NO && anyByIndex == NO)
	{
		color = UIColor.systemYellowColor;
	}
	else if(anyByClass == YES && anyByIndex == NO)
	{
		color = UIColor.systemOrangeColor;
	}
		
	if(color == nil)
	{
		color = UIColor.systemRedColor;
	}
	
	CGRect safeBounds;
	
	if([view isKindOfClass:UIScrollView.class])
	{
		safeBounds = UIEdgeInsetsInsetRect(view.bounds, view.safeAreaInsets);
	}
	else
	{
		safeBounds = view.bounds;
	}
	
	CGRect frame = [view.window convertRect:safeBounds fromView:view];
	
	visualizer.userInteractionEnabled = NO;
	visualizer.alpha = 1.0;
	visualizer.backgroundColor = [color colorWithAlphaComponent:0.4];
	visualizer.frame = frame;
	visualizer.layer.cornerRadius = MIN(8, MIN(visualizer.frame.size.width, visualizer.frame.size.height) / 2);
	visualizer.layer.borderWidth = 2.0;
	visualizer.layer.borderColor = color.CGColor;
	[captureControlWindow.rootViewController.view addSubview:visualizer];
	
	NSMutableArray<UIImageView*>* imageViews = [NSMutableArray new];
	[systemImageNames enumerateObjectsUsingBlock:^(NSString * _Nonnull systemImageName, NSUInteger idx, BOOL * _Nonnull stop) {
		CGFloat minImageSize = MIN(30, MIN(CGRectGetWidth(frame) * 0.75, CGRectGetHeight(frame) * 0.75));
		
		UIImage* image = [UIImage systemImageNamed:systemImageName withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:MAX(minImageSize, MIN(CGRectGetWidth(frame) * 0.45, CGRectGetHeight(frame) * 0.45)) weight:UIImageSymbolWeightMedium]];
		UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
		if(applyConstraints)
		{
			imageView.translatesAutoresizingMaskIntoConstraints = NO;
		}
		imageView.tintColor = UIColor.whiteColor;
		imageView.transform = transforms[idx].CGAffineTransformValue;
		
		if(CGRectContainsRect(CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame)), (CGRect){0, 0, image.size}))
		{
			imageView.contentMode = UIViewContentModeCenter;
		}
		else
		{
			imageView.contentMode = UIViewContentModeScaleAspectFit;
		}
		
		[visualizer addSubview:imageView];
		
		if(applyConstraints)
		{
			[NSLayoutConstraint activateConstraints:@[
				[imageView.topAnchor constraintEqualToAnchor:visualizer.topAnchor],
				[imageView.bottomAnchor constraintEqualToAnchor:visualizer.bottomAnchor],
				[imageView.leadingAnchor constraintEqualToAnchor:visualizer.leadingAnchor],
				[imageView.trailingAnchor constraintEqualToAnchor:visualizer.trailingAnchor],
			]];
		}
		
		[imageViews addObject:imageView];
	}];
	
	if(imageViews.count > 0)
	{
		visualizer.imageViews = imageViews;
	}
	
	return visualizer;
}

+ (void)_blinkVisualizerView:(UIView*)view
{
	static const CGFloat initialAlpha = 1.0;
	[UIView performWithoutAnimation:^{
		view.alpha = initialAlpha;
	}];
	
	[UIView animateKeyframesWithDuration:0.4 delay:0.0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState | UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 / 3.0 animations:^{
			view.alpha = 0.0;
		}];
		[UIView addKeyframeWithRelativeStartTime:1.0 / 3.0 relativeDuration:2.0 / 3.0 animations:^{
			view.alpha = initialAlpha * 0.8;
		}];
		[UIView addKeyframeWithRelativeStartTime:2.0 / 3.0 relativeDuration:1.0 animations:^{
			view.alpha = 0.0;
		}];
	} completion:^(BOOL finished) {
		[view removeFromSuperview];
	}];
}

+ (void)_flashVisualizerView:(UIView*)view
{
	static const CGFloat initialAlpha = 0.8;
	[UIView performWithoutAnimation:^{
		view.alpha = initialAlpha;
	}];
	[UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
		view.alpha = 0.0;
	} completion:^(BOOL finished) {
		[view removeFromSuperview];
	}];
}

+ (void)_slowFlashVisualizerView:(UIView*)view
{
	static const CGFloat initialAlpha = 0.8;
	[UIView performWithoutAnimation:^{
		view.alpha = initialAlpha;
	}];
	[UIView animateWithDuration:0.8 delay:0.0 options:0 animations:^{
		view.alpha = 0.0;
	} completion:^(BOOL finished) {
		[view removeFromSuperview];
	}];
}

+ (void)_animateScrollVisualizerView:(_DTXVisualizedView*)view direction:(CGPoint)dir
{
	__block CGFloat startingY = 0.0;
	
	[UIView performWithoutAnimation:^{
		view.clipsToBounds = YES;
		[view layoutIfNeeded];
		if(view.imageViews.firstObject != view.imageViews.lastObject)
		{
			startingY = 15;
			view.imageViews.lastObject.frame = view.bounds;
			view.imageViews.lastObject.contentMode = UIViewContentModeTop;
		}
		
		view.imageViews.firstObject.frame = CGRectMake(0, startingY, CGRectGetWidth(view.bounds), CGRectGetHeight(view.bounds) - startingY);
		
		[view layoutIfNeeded];
	}];
	
	CGFloat x = dir.x < 0 ? CGRectGetMinX(view.bounds) : CGRectGetMaxX(view.bounds);
	CGFloat y = dir.y < 0 ? CGRectGetMinY(view.bounds) + startingY : CGRectGetMaxY(view.bounds);
	
	CGRect newFrame = view.bounds;
	
	if(dir.y != 0)
	{
		newFrame = CGRectMake(CGRectGetMinX(view.bounds), y, CGRectGetWidth(view.bounds), 0);
		view.imageViews.firstObject.contentMode = dir.y < 0 ? UIViewContentModeBottom : UIViewContentModeTop;
	}
	else if(dir.x != 0)
	{
		newFrame = CGRectMake(x, CGRectGetMinY(view.bounds), 0, CGRectGetHeight(view.bounds));
	}
	
	[UIView animateKeyframesWithDuration:0.5 delay:0.0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
			view.imageViews.firstObject.frame = newFrame;
		}];
		[UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
			view.alpha = 0.0;
			[view layoutIfNeeded];
		}];
	} completion:^(BOOL finished) {
		[view removeFromSuperview];
	}];
}

+ (void)_systemDeleteVisualizerView:(UIView*)view
{
	[UIView performSystemAnimation:UISystemAnimationDelete onViews:@[view] options:UIViewAnimationOptionBeginFromCurrentState animations:nil completion:^(BOOL finished) {
		[view removeFromSuperview];
	}];
}

+ (void)_visualizeTapAtView:(UIView*)view withAction:(DTXRecordedAction*)action
{
	NSString* normalTap = @"hand.point.right.fill";
	CGAffineTransform transform = CGAffineTransformMakeRotation(-M_PI_2);
	if(@available(iOS 14.0, *))
	{
		normalTap = @"hand.tap.fill";
		transform = CGAffineTransformIdentity;
	}
	
	UIView* visualizer = [self _visualizerViewForView:view action:action systemImageNames:@[normalTap] imageViewTransforms:@[[NSValue valueWithCGAffineTransform:transform]] applyConstraints:YES];
	
	[self _blinkVisualizerView:visualizer];
}

+ (void)_visualizeLongPressAtView:(UIView*)view withAction:(DTXRecordedAction*)action
{
	UIView* visualizer = [self _visualizerViewForView:view action:action systemImageNames:@[@"hand.point.left.fill"] imageViewTransforms:@[[NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(-M_PI_2)]] applyConstraints:YES];
	
	[self _slowFlashVisualizerView:visualizer];
}


+ (void)_visualizeDatePickerChangeDate:(UIDatePicker*)view withAction:(DTXRecordedAction*)action
{
	UIView* visualizer = [self _visualizerViewForView:view action:action systemImageName:@"calendar"];
	
	[self _blinkVisualizerView:visualizer];
}

+ (void)_addTapWithView:(UIView*)view event:(UIEvent*)event tapGestureRecognizer:(UITapGestureRecognizer*)tgr fromRN:(BOOL)fromRN
{
	NSAssert(view != nil, @"View cannot be nil");
	IGNORE_IF_FROM_LAST_EVENT
	IGNORE_RECORDING_WINDOW(view)
	
	DTXRecordedAction* action = [DTXRecordedAction tapActionWithView:view event:event tapGestureRecognizer:tgr isFromRN:fromRN];
	if(action != nil)
	{
		DTXAddAction(action);
//		NSLog(@"📣 Tapped control: %@", control.class);
		
		[self _visualizeTapAtView:view withAction:action];
	}
}

+ (void)addControlTapWithControl:(UIControl*)control withEvent:(UIEvent*)event
{
	[self _addTapWithView:control event:event tapGestureRecognizer:nil fromRN:NO];
}

+ (void)addTapWithView:(UIView*)view withEvent:(UIEvent*)event
{
	[self _addTapWithView:view event:event tapGestureRecognizer:nil fromRN:NO];
}

+ (void)addGestureRecognizerTap:(UITapGestureRecognizer*)tgr withEvent:(UIEvent*)event
{
	[self _addTapWithView:tgr.view event:event tapGestureRecognizer:tgr fromRN:NO];
}

+ (void)addRNGestureRecognizerTapWithTouch:(UITouch*)touch withEvent:(UIEvent*)event;
{
	if(touch.view == nil)
	{
		return;
	}
	
	[self _addTapWithView:touch.view event:event tapGestureRecognizer:nil fromRN:YES];
}

+ (void)addRNGestureRecognizerLongPressWithTouch:(UITouch*)touch withEvent:(nullable UIEvent*)event
{
	if(touch.view == nil)
	{
		return;
	}
	
	[self addLongPressWithView:touch.view duration:NSUserDefaults.standardUserDefaults.dtxrec_rnLongPressDelay withEvent:event];
}

+ (void)addLongPressWithView:(UIView*)view duration:(NSTimeInterval)duration withEvent:(UIEvent*)event
{
	IGNORE_RECORDING_WINDOW(view)
	
	DTXRecordedAction* action = [DTXRecordedAction longPressActionWithView:view duration:duration event:event];
	if(action != nil)
	{
		DTXAddAction(action);
		
		[self _visualizeLongPressAtView:view withAction:action];
	}
}

+ (void)addGestureRecognizerLongPress:(UIGestureRecognizer*)tgr duration:(NSTimeInterval)duration withEvent:(UIEvent*)event
{
	return [self addLongPressWithView:tgr.view duration:duration withEvent:event];
}

+ (void)_enhanceLastScrollEventIfNeededForAction:(DTXRecordedAction*)targetAction
{
	DTXUpdateAction(^BOOL(DTXRecordedAction *action, BOOL* remove) {
		if(action.allowsUpdates == NO ||
		   action.actionType != DTXRecordedActionTypeScroll)
		{
			return NO;
		}
		
		if(NSUserDefaults.standardUserDefaults.dtxrec_convertScrollEventsToWaitfor == NO)
		{
			return NO;
		}
		
		return [action enhanceScrollActionWithTargetElement:targetAction.element];
	});
}

+ (BOOL)_coalesceScrollViewEvent:(UIScrollView*)scrollView fromDeltaOriginOffset:(CGPoint)deltaOriginOffset toNewOffset:(CGPoint)newOffset
{
	return DTXUpdateAction(^BOOL(DTXRecordedAction *prevAction, BOOL* remove) {
		if(NSUserDefaults.standardUserDefaults.dtxrec_coalesceScrollEvents == NO)
		{
			return NO;
		}
		
		if(prevAction.allowsUpdates == NO || prevAction.actionType != DTXRecordedActionTypeScroll || [prevAction.element isReferencingView:scrollView] == NO)
		{
			return NO;
		}
		
		if([prevAction updateScrollActionWithScrollView:scrollView fromDeltaOriginOffset:deltaOriginOffset toNewOffset:newOffset] == NO)
		{
			//The coalescing operation resulted in zero change, so remove the entire scroll action.
			*remove = YES;
			
			return YES;
		}
		
		return YES;
	});
}

+ (void)addScrollEvent:(UIScrollView*)scrollView fromOriginOffset:(CGPoint)originOffset withEvent:(UIEvent *)event
{
	IGNORE_RECORDING_WINDOW(scrollView)
	
	[self addScrollEvent:scrollView fromOriginOffset:originOffset toNewOffset:scrollView.contentOffset withEvent:event];
}

static inline CGPoint DTXDirectionOfScroll(DTXRecordedAction* action)
{
	if([action.actionArgs.lastObject isEqualToString:@"up"])
	{
		return CGPointMake(0, -1);
	}
	if([action.actionArgs.lastObject isEqualToString:@"down"])
	{
		return CGPointMake(0, 1);
	}
	if([action.actionArgs.lastObject isEqualToString:@"left"])
	{
		return CGPointMake(-1, 0);
	}
	if([action.actionArgs.lastObject isEqualToString:@"right"])
	{
		return CGPointMake(1, 0);
	}
	
	return CGPointZero;
}

+ (void)_visualizeScrollOfView:(UIView*)view action:(DTXRecordedAction*)action
{
	CGPoint direction = DTXDirectionOfScroll(action);
	
	_DTXVisualizedView* visualizer = [self _visualizerViewForView:view action:action systemImageNames:@[direction.y < 0 ? @"arrow.up" : direction.y > 0 ? @"arrow.down" : direction.x < 0 ? @"arrow.left" : direction.x > 0 ? @"arrow.right" : @"arrow.2.circlepath"] applyConstraints:NO];
	
	[self _animateScrollVisualizerView:visualizer direction:direction];
}

+ (void)_visualizeScrollToTopOfView:(UIView*)view action:(DTXRecordedAction*)action
{
	_DTXVisualizedView* visualizer = [self _visualizerViewForView:view action:action systemImageNames:@[@"arrow.up", @"minus"] imageViewTransforms:@[[NSValue valueWithCGAffineTransform:CGAffineTransformIdentity], [NSValue valueWithCGAffineTransform:CGAffineTransformMakeScale(2.0, 1.0)]] applyConstraints:NO];
	
	[self _animateScrollVisualizerView:visualizer direction:CGPointMake(0, -1)];
}

+ (void)_visualizeScrollCancelOfView:(UIView*)view action:(DTXRecordedAction*)action
{
	UIView* visualizer = [self _visualizerViewForView:view action:action systemImageName:@"hand.raised.fill"];
	
	[self _systemDeleteVisualizerView:visualizer];
}

+ (void)addScrollEvent:(UIScrollView*)scrollView fromOriginOffset:(CGPoint)originOffset toNewOffset:(CGPoint)newOffset withEvent:(UIEvent *)event
{
	IGNORE_RECORDING_WINDOW(scrollView)
	
//	NSLog(@"📣 %@->%@", @(originOffset), @(newOffset));
	
	DTXRecordedAction* action = [DTXRecordedAction scrollActionWithView:scrollView originOffset:originOffset newOffset:newOffset event:event];
	
	if(action == nil)
	{
		return;
	}
	
	if(action.isCancelled)
	{
		[self _visualizeScrollCancelOfView:scrollView action:action];
		
		return;
	}
	
	[self _visualizeScrollOfView:scrollView action:action];
	
	if([self _coalesceScrollViewEvent:scrollView fromDeltaOriginOffset:originOffset toNewOffset:newOffset] == YES)
	{
		return;
	}
	
	DTXAddAction(action);
}

+ (void)addDatePickerDateChangeEvent:(UIDatePicker*)datePicker withEvent:(UIEvent*)event
{
	IGNORE_RECORDING_WINDOW(datePicker)
	
	DTXRecordedAction* action = [DTXRecordedAction datePickerDateChangeActionWithView:datePicker event:event];
	if(action != nil)
	{
		DTXAddAction(action);
		
		[self _visualizeDatePickerChangeDate:datePicker withAction:action];
	}
}

+ (void)_visualizePickerValueChangeAtView:(UIPickerView*)pickerView component:(NSInteger)component withAction:(DTXRecordedAction*)action
{
	UIView* container = [[pickerView tableViewForColumn:component] _containerView];
	CGRect frame = [pickerView.coordinateSpace convertRect:container.accessibilityFrame toCoordinateSpace:captureControlWindow.coordinateSpace];
	UIView* fakeView = [[UIView alloc] initWithFrame:frame];
	[captureControlWindow addSubview:fakeView];
	
	UIView* visualizer = [self _visualizerViewForView:fakeView action:action systemImageName:@"rectangle.fill.badge.checkmark"];
	
	[self _blinkVisualizerView:visualizer];
	
	[fakeView removeFromSuperview];
}

+ (void)addPickerViewValueChangeEvent:(UIPickerView*)pickerView component:(NSInteger)component withEvent:(UIEvent*)event
{
	IGNORE_RECORDING_WINDOW(pickerView)
	
	DTXRecordedAction* action = [DTXRecordedAction pickerViewValueChangeActionWithView:pickerView component:component event:event];
	if(action != nil)
	{
		DTXAddAction(action);

		[self _visualizePickerValueChangeAtView:pickerView component:component withAction:action];
	}
}

+ (void)_visualizeSliderAdjust:(UISlider*)view withAction:(DTXRecordedAction*)action
{
	UIView* visualizer = [self _visualizerViewForView:view action:action systemImageName:@"slider.horizontal.3"];
	
	[self _blinkVisualizerView:visualizer];
}

+ (void)addSliderAdjustEvent:(UISlider*)slider withEvent:(UIEvent*)event
{
	IGNORE_RECORDING_WINDOW(slider)
	
	DTXRecordedAction* action = [DTXRecordedAction sliderAdjustActionWithView:slider event:event];
	if(action != nil)
	{
		DTXAddAction(action);

		[self _visualizeSliderAdjust:slider withAction:action];
	}
}

+ (void)addScrollToTopEvent:(UIScrollView*)scrollView withEvent:(UIEvent*)event
{
	IGNORE_RECORDING_WINDOW(scrollView)
	
	DTXRecordedAction* action = [DTXRecordedAction scrollToTopActionWithView:scrollView event:event];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([[scrollView valueForKeyPath:@"animation.duration"] doubleValue] * 0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self _visualizeScrollToTopOfView:scrollView action:action];
	});
	
	DTXAddAction(action);
}

+ (void)_visualizeTextChangeOfView:(UIView*)view action:(DTXRecordedAction*)action
{
	if(previousTextChangeVisualizer == nil || previousTextChangeVisualizer.superview == nil)
	{
		previousTextChangeVisualizer = [self _visualizerViewForView:view action:action systemImageName:@"text.cursor"];
	}
	
	[self _flashVisualizerView:previousTextChangeVisualizer];
}

+ (void)_visualizeReturnTapInView:(UIView*)view action:(DTXRecordedAction*)action
{
	if(previousTextChangeVisualizer == nil || previousTextChangeVisualizer.superview == nil)
	{
		previousTextChangeVisualizer = [self _visualizerViewForView:view action:action systemImageName:@"return"];
	}
	
	[self _flashVisualizerView:previousTextChangeVisualizer];
}

+ (BOOL)_coalesceTextEvent:(UIView<UITextInput>*)textInput text:(NSString*)text
{
	return DTXUpdateAction(^BOOL(DTXRecordedAction *prevAction, BOOL* remove) {
		if(NSUserDefaults.standardUserDefaults.dtxrec_coalesceTextEvents == NO)
		{
			return NO;
		}
		
		if(prevAction.allowsUpdates == NO || prevAction.actionType != DTXRecordedActionTypeReplaceText || [prevAction.element isReferencingView:textInput] == NO)
		{
			return NO;
		}

		[prevAction updateReplaceTextActionWithView:textInput text:text];
		return YES;
	});
}

+ (void)addTextChangeEvent:(UIView<UITextInput>*)textInput
{
	IGNORE_RECORDING_WINDOW(textInput)
	
	NSString* text = [textInput textInRange:[textInput textRangeFromPosition:textInput.beginningOfDocument toPosition:textInput.endOfDocument]];
	DTXRecordedAction* action = [DTXRecordedAction replaceTextActionWithView:textInput text:text event:nil];
	if(action == nil)
	{
		return;
	}
	
	[self _visualizeTextChangeOfView:textInput action:action];
	
	if([self _coalesceTextEvent:textInput text:text] == YES)
	{
		return;
	}
	
	DTXAddAction(action);
}

+ (void)addTextReturnKeyEvent:(UIView<UITextInput>*)textInput
{
	IGNORE_RECORDING_WINDOW(textInput)
	
	DTXRecordedAction* action = [DTXRecordedAction returnKeyTextActionWithView:textInput event:nil];
	if(action == nil)
	{
		return;
	}
	
	[self _visualizeReturnTapInView:textInput action:action];
	
	if([self _coalesceTextEvent:textInput text:@"\n"] == YES)
	{
		return;
	}
	
	DTXAddAction(action);
}

+ (void)addDeviceShake
{
	DTXAddAction([DTXRecordedAction shakeDeviceAction]);
	[captureControlWindow visualizeShakeDevice];
}

+ (void)addTakeScreenshot
{
	[self addTakeScreenshotWithName:nil];
}

+ (void)addTakeScreenshotWithName:(NSString*)screenshotName
{
	DTXAddAction([DTXRecordedAction takeScreenshotActionWithName:screenshotName]);
	[captureControlWindow visualizeTakeScreenshotWithName:screenshotName];
}

+ (void)addCodeComment:(NSString*)comment
{
	DTXAddAction([DTXRecordedAction codeCommentAction:comment]);
	[captureControlWindow visualizeAddComment:comment];
}

+ (void)_sendPing
{
	DTXSendCommand(@{@"type": @"ping"});
}

+ (BOOL)_hasRecordedActions
{
#if DEBUG
	if([NSUserDefaults.standardUserDefaults boolForKey:@"DTXGenerateArtwork"])
	{
		return YES;
	}
#endif
	
	return recordedActions.count > 0;
}

#pragma mark NSNetServiceDelegate

+ (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
	[self _presentError:[NSError errorWithDomain:@"" code:[errorDict[NSNetServicesErrorCode] unsignedIntValue] userInfo:@{NSLocalizedDescriptionKey: @"Unable to connec to the recording service."}] completionHandler:^{
		[self stopRecording];
	}];
}

+ (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	dtx_log_info(@"Resolved recording service: %@", sender);
	
	_currentConnection = [[DTXSocketConnection alloc] initWithHostName:sender.hostName port:sender.port delegateQueue:nil];
	_currentConnection.delegate = (id)self;
	[_currentConnection open];
	
	__block dispatch_source_t pingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _currentConnection.delegateQueue);
	_pingTimer = pingTimer;
	int64_t interval = 0.25 * NSEC_PER_SEC;
	dispatch_source_set_timer(_pingTimer, dispatch_time(DISPATCH_TIME_NOW, 0), interval, 0);
	
	dispatch_source_set_event_handler(_pingTimer, ^ {
		[DTXUIInteractionRecorder _sendPing];
	});
	
	dispatch_resume(_pingTimer);
	
	dispatch_async(dispatch_get_main_queue(), ^{
		_appearanceBlock();
		_appearanceBlock = nil;
	});
}

#pragma mark DTXSocketConnectionDelegate

+ (void)readClosedForSocketConnection:(DTXSocketConnection*)socketConnection
{
	dtx_log_info(@"Socket connection closed for reading.");
	
	[self stopRecording];
}

+ (void)writeClosedForSocketConnection:(DTXSocketConnection*)socketConnection
{
	dtx_log_info(@"Socket connection closed for writing.");
	
	[self stopRecording];
}


@end

@implementation DTXUIInteractionRecorder (Deprecated)

+ (void)beginRecording
{
	[self startRecording];
}

+ (void)endRecording
{
	[self stopRecording];
}

@end
