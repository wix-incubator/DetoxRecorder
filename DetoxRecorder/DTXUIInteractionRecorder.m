//
//  DTXUIInteractionRecorder.m
//  UI
//
//  Created by Leo Natan (Wix) on 4/9/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "DTXUIInteractionRecorder.h"
#import "DTXCaptureControlWindow.h"
#import "DTXRecordedAction.h"
#import "DTXAppleInternals.h"
#import "NSUserDefaults+RecorderUtils.h"

#define IGNORE_RECORDING_WINDOW(view) if(view.window == captureControlWindow) { return; }

@interface _DTXVisualizedView : UIView

@property (nonatomic, strong) NSArray<UIImageView*>* imageViews;

@end
@implementation _DTXVisualizedView @end

@implementation DTXUIInteractionRecorder

static __weak id<DTXUIInteractionRecorderDelegate> delegate;
static BOOL startedByUser;
static NSMutableArray<DTXRecordedAction*>* recordedActions;
static DTXCaptureControlWindow* captureControlWindow;
static UIView* previousTextChangeVisualizer;
NSFileHandle* currentFile;
unsigned long long currentFileOffset;
unsigned long long previousFileOffset;
NSData* fileOutro;

DTX_ALWAYS_INLINE
static void _DTXWriteActionToFile(DTXRecordedAction* action)
{
	NSData* data = [[NSString stringWithFormat:@"\t\t%@\n", action.detoxDescription] dataUsingEncoding:NSUTF8StringEncoding];
	[currentFile truncateAtOffset:currentFileOffset error:NULL];
	[currentFile writeData:data error:NULL];
	previousFileOffset = currentFileOffset;
	currentFileOffset += data.length;
}

DTX_ALWAYS_INLINE
static void _DTXWriteOutroFile()
{
	[currentFile writeData:fileOutro error:NULL];
}

DTX_ALWAYS_INLINE
static void DTXAddAction(DTXRecordedAction* action)
{
	[recordedActions addObject:action];
	
	_DTXWriteActionToFile(action);
	_DTXWriteOutroFile();
	
	if([delegate respondsToSelector:@selector(interactionRecorderDidAddTestCommand:)])
	{
		[delegate interactionRecorderDidAddTestCommand:action.detoxDescription];
	}
}

DTX_ALWAYS_INLINE
static BOOL DTXUpdateAction(BOOL (^updateBlock)(DTXRecordedAction* action, BOOL* remove))
{
	DTXRecordedAction* action = recordedActions.lastObject;
	
	BOOL remove = NO;
	BOOL rv = updateBlock(action, &remove);
	
	if(remove)
	{
		[recordedActions removeLastObject];
	}
	
	if(rv == YES)
	{
		[currentFile seekToOffset:previousFileOffset error:NULL];
		
		if(remove == NO)
		{
			currentFileOffset = previousFileOffset;
			_DTXWriteActionToFile(action);
		}
		
		_DTXWriteOutroFile();
	}
	
	if(rv == YES && [delegate respondsToSelector:@selector(interactionRecorderDidReplaceUpdateTestCommandWithCommand:)])
	{
		[delegate interactionRecorderDidReplaceUpdateTestCommandWithCommand:remove ? nil : action.detoxDescription];
	}
	
	return rv;
}

+ (void)load
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		if([NSUserDefaults.standardUserDefaults boolForKey:@"DTXRecStartRecording"] == YES)
		{
			[self _beginRecordingByUser:NO];
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

+ (void)beginRecording
{
	[self _beginRecordingByUser:YES];
}

+ (void)_presentError:(NSError*)error completionHandler:(dispatch_block_t)handler
{
	UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"Error Creating Test File" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
	[errorAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		if(handler) { handler(); }
	}]];
}

+ (void)_beginRecordingByUser:(BOOL)byUser;
{
	if(captureControlWindow != nil)
	{
		return;
	}
	
	startedByUser = byUser;
	
	recordedActions = [NSMutableArray new];
	[DTXRecordedAction resetScreenshotCounter];
	
	captureControlWindow = [[DTXCaptureControlWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
	
	NSString* testNamePath = [NSUserDefaults.standardUserDefaults stringForKey:@"DTXRecTestOutputPath"];
	NSString* testName = [NSUserDefaults.standardUserDefaults stringForKey:@"DTXRecTestName"] ?: @"My Recorded Test";
	
	if(testNamePath != nil)
	{
		[NSFileManager.defaultManager createFileAtPath:testNamePath contents:nil attributes:nil];
		NSError* error = nil;
		currentFile = [NSFileHandle fileHandleForWritingToURL:[NSURL fileURLWithPath:testNamePath] error:&error];
		if(currentFile == nil)
		{
			[self _presentError:error completionHandler:^{
				[self endRecording];
			}];
		}
	}

	NSData* intro = [[NSString stringWithFormat:@"describe('Recorded suite', () => {\n\tit('%@', async () => {\n", testName] dataUsingEncoding:NSUTF8StringEncoding];
	fileOutro = [@"\t}\n}" dataUsingEncoding:NSUTF8StringEncoding];
	
	[currentFile writeData:intro error:NULL];
	[currentFile writeData:fileOutro error:NULL];
	
	[currentFile seekToOffset:intro.length error:NULL];
	previousFileOffset = currentFileOffset = intro.length;
}

+ (void)_exitIfNeeded
{
	if(startedByUser == NO &&
	   (([delegate respondsToSelector:@selector(interactionRecorderShouldExitApp)] == NO && [NSUserDefaults.standardUserDefaults boolForKey:@"DTXRecNoExit"] == NO) ||
	   [delegate interactionRecorderShouldExitApp]))
	{
		exit(0);
	}
}

+ (void)endRecording
{
	NSError* error = nil;
	BOOL delayExit = NO;
	
	if([currentFile closeAndReturnError:&error] == NO)
	{
		delayExit = YES;
		[self _presentError:error completionHandler:^{
			[self _exitIfNeeded];
		}];
	}
	
	NSMutableArray<NSString*>* detoxCommands = nil;
	if([delegate respondsToSelector:@selector(interactionRecorderDidEndRecordingWithTestCommands:)])
	{
		detoxCommands = [NSMutableArray new];
	}
	
	[recordedActions enumerateObjectsUsingBlock:^(DTXRecordedAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString* detoxDescription = obj.detoxDescription;
		[detoxCommands addObject:detoxDescription];
	}];
	
	if(detoxCommands != nil)
	{
		[delegate interactionRecorderDidEndRecordingWithTestCommands:detoxCommands];
	}
	
	recordedActions = nil;
	captureControlWindow.hidden = YES;
	captureControlWindow = nil;
	
	if(delayExit == NO)
	{
		[self _exitIfNeeded];
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

static void _traverseElementMatchersAndFill(DTXRecordedElement* element, BOOL* anyById, BOOL* anyByLabel, BOOL* anyByClass, BOOL* anyByIndex, BOOL* hasAncestorChain)
{
	if(element == nil)
	{
		return;
	}
	
	*anyByIndex |= element.requiresAtIndex;
	
	[element.matchers enumerateObjectsUsingBlock:^(DTXRecordedElementMatcher * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		*anyById |= (obj.matcherType == DTXRecordedElementMatcherTypeById);
		*anyByLabel |= (obj.matcherType == DTXRecordedElementMatcherTypeByLabel);
		*anyByClass |= (obj.matcherType == DTXRecordedElementMatcherTypeByType);
	}];
	
	*hasAncestorChain |= (element.ancestorElement != nil);
	
	_traverseElementMatchersAndFill(element.ancestorElement, anyById, anyByLabel, anyByClass, anyByIndex, hasAncestorChain);
}

+ (_DTXVisualizedView*)_visualizerViewForView:(UIView*)view action:(DTXRecordedAction*)action systemImageNames:(NSArray<NSString*>*)systemImageNames imageViewTransforms:(NSArray<NSValue* /*CGAffineTransform*/>*)transforms applyConstraints:(BOOL)applyConstraints
{
	_DTXVisualizedView* visualizer = [_DTXVisualizedView new];
	
	UIColor* color;
	
	BOOL anyById = NO;
	BOOL anyByLabel = NO;
	BOOL anyByClass = NO;
	BOOL anyByIndex = NO;
	BOOL hasAncestorChain = NO;
	
	_traverseElementMatchersAndFill(action.element, &anyById, &anyByLabel, &anyByClass, &anyByIndex, &hasAncestorChain);
	
	if(anyById == YES && anyByIndex == NO)
	{
		color = UIColor.systemGreenColor;
	}
	else if((anyByLabel == YES || anyByClass == YES) && anyByIndex == NO)
	{
		color = UIColor.systemOrangeColor;
	}
		
	if(color == nil)
	{
		color = UIColor.systemRedColor;
	}
	
	CGRect frame = [view.window convertRect:view.bounds fromView:view];
	
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
	BOOL xy = NSUserDefaults.standardUserDefaults.dtxrec_attemptXYRecording;
	UIView* visualizer = [self _visualizerViewForView:view action:action systemImageNames:@[xy ? @"hand.draw.fill" : @"hand.point.right.fill"] imageViewTransforms:@[[NSValue valueWithCGAffineTransform:xy ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(-M_PI_2)]] applyConstraints:YES];
	
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

+ (void)_addTapWithView:(UIView*)view event:(UIEvent*)event fromRN:(BOOL)fromRN
{
	IGNORE_IF_FROM_LAST_EVENT
	IGNORE_RECORDING_WINDOW(view)
	
	DTXRecordedAction* action = [DTXRecordedAction tapActionWithView:view event:event isFromRN:fromRN];
	if(action != nil)
	{
		[self _enhanceLastScrollEventIfNeededForElement:action.element];
		
		DTXAddAction(action);
//		NSLog(@"📣 Tapped control: %@", control.class);
		
		[self _visualizeTapAtView:view withAction:action];
	}
}

+ (void)addControlTapWithControl:(UIControl*)control withEvent:(UIEvent*)event
{
	[self _addTapWithView:control event:event fromRN:NO];
}

+ (void)addTapWithView:(UIView*)view withEvent:(UIEvent*)event
{
	[self _addTapWithView:view event:event fromRN:NO];
}

+ (void)addGestureRecognizerTap:(UIGestureRecognizer*)tgr withEvent:(UIEvent*)event
{
	[self _addTapWithView:tgr.view event:event fromRN:NO];
}

+ (void)addRNGestureRecognizerTapTouch:(UITouch*)touch withEvent:(UIEvent*)event;
{
	[self _addTapWithView:touch.view event:event fromRN:YES];
}

+ (void)addGestureRecognizerLongPress:(UIGestureRecognizer*)tgr duration:(NSTimeInterval)duration withEvent:(UIEvent*)event
{
	IGNORE_RECORDING_WINDOW(tgr.view)
	
	DTXRecordedAction* action = [DTXRecordedAction longPressActionWithView:tgr.view duration:duration event:event];
	if(action != nil)
	{
		[self _enhanceLastScrollEventIfNeededForElement:action.element];
		
		DTXAddAction(action);
		
		[self _visualizeLongPressAtView:tgr.view withAction:action];
	}
}

+ (void)_enhanceLastScrollEventIfNeededForElement:(DTXRecordedElement*)element
{
	DTXUpdateAction(^BOOL(DTXRecordedAction *action, BOOL* remove) {
		if(action.allowsUpdates == NO ||
		   action.actionType != DTXRecordedActionTypeScroll)
		{
			return NO;
		}
		
		return [action enhanceScrollActionWithTargetElement:element];
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
			
			return NO;
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
	UIView* visualizer = [self _visualizerViewForView:view action:action systemImageName:@"arrow.2.circlepath"];
	
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

+ (void)addTextChangeEvent:(UIView<UITextInput>*)textInput
{
	IGNORE_RECORDING_WINDOW(textInput)
	
	NSString* text = [textInput textInRange:[textInput textRangeFromPosition:textInput.beginningOfDocument toPosition:textInput.endOfDocument]];
	DTXRecordedAction* action = [DTXRecordedAction replaceTextActionWithView:textInput text:text event:nil];
	if(action == nil)
	{
		return;
	}
	
	DTXAddAction(action);
	[self _visualizeTextChangeOfView:textInput action:action];
}

+ (void)addTextReturnKeyEvent:(UIView<UITextInput>*)textInput
{
	IGNORE_RECORDING_WINDOW(textInput)
	
	DTXRecordedAction* action = [DTXRecordedAction returnKeyTextActionWithView:textInput event:nil];
	if(action == nil)
	{
		return;
	}
	
	DTXAddAction(action);
	[self _visualizeReturnTapInView:textInput action:action];
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

@end
