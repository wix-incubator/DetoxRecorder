//
//  DTXRecordedElement.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecordedElement.h"
#import "UIView+RecorderUtils.h"
#import "NSString+QuotedStringForJS.h"

DTXRecordedElementMatcherType const DTXRecordedElementMatcherTypeById = @"by.id";
DTXRecordedElementMatcherType const DTXRecordedElementMatcherTypeByType = @"by.type";
DTXRecordedElementMatcherType const DTXRecordedElementMatcherTypeByLabel = @"by.label";
DTXRecordedElementMatcherType const DTXRecordedElementMatcherTypeByText = @"by.text";

@interface DTXRecordedElementMatcher ()

@property (nonatomic, strong, readwrite) DTXRecordedElementMatcherType matcherType;
@property (nonatomic, strong, readwrite) NSArray* matcherArgs;

@end

@implementation DTXRecordedElementMatcher

- (NSString*)detoxDescription;
{
	NSMutableString* rv = [NSMutableString new];
	[rv appendFormat:@"%@(", self.matcherType];
	
	[rv appendString:[[self.matcherArgs dtx_mapObjectsUsingBlock:^id _Nonnull(id  _Nonnull obj, NSUInteger idx) {
		if([obj isKindOfClass:NSString.class])
		{
			return [obj dtx_quotedStringRepresentationForJS];
		}
		
		return [obj description];
	}] componentsJoinedByString:@", "]];
	[rv appendString:@")"];
	return rv;
}

- (NSString *)description
{
	return self.detoxDescription;
}

static void _DTXDeepMacherDescription(NSArray<DTXRecordedElementMatcher*>* matchers, NSUInteger idx, NSMutableString* rv)
{
	if(idx == matchers.count)
	{
		return;
	}
	
	if(idx > 0)
	{
		[rv appendString:@".and("];
	}
	
	[rv appendString:matchers[idx].detoxDescription];
	_DTXDeepMacherDescription(matchers, idx + 1, rv);
	
	if(idx > 0)
	{
		[rv appendString:@")"];
	}
}

+ (NSString*)detoxDescriptionForMatchers:(NSArray<DTXRecordedElementMatcher*>*)matchers
{
	NSMutableString* rv = [NSMutableString new];
	_DTXDeepMacherDescription(matchers, 0, rv);
	return rv;
}

@end


@interface DTXRecordedElement ()

@property (nonatomic, readwrite, copy) NSArray<DTXRecordedElementMatcher*>* matchers;
@property (nonatomic, readwrite) BOOL requiresAtIndex;
@property (nonatomic, readwrite) NSInteger atIndex;
@property (nonatomic, readwrite) DTXRecordedElement* ancestorElement;

@property (nonatomic, strong) Class viewClass;
@property (nonatomic, strong) NSString* chainDescription;
@property (nonatomic, strong) NSArray<NSString*>* superviewChain;

@end

static NSString* _DTXBestEffortAccessibilityIdentifierForView(UIView* view, UIAccessibilityTraits allowedLookupTraits)
{
	if(view.accessibilityIdentifier.length > 0)
	{
		return view.accessibilityIdentifier;
	}
	
	if([NSStringFromClass(view.class) hasSuffix:@"BarButton"])
	{
		//For bar buttons with no identifiers, quickly fail. Other logic will take the title instead of an identifier.
		return nil;
	}
	
	if([view isKindOfClass:NSClassFromString(@"RCTCustomScrollView")])
	{
		return view.superview.accessibilityIdentifier;
	}
	
	UIView* currView = view;
	while(allowedLookupTraits != 0 && currView != nil && currView.accessibilityIdentifier.length == 0 && (currView.accessibilityTraits & allowedLookupTraits) == 0)
	{
		currView = currView.superview;
	}
	
	return currView.accessibilityIdentifier;
}

#define IDX_IF_NEEDED if(found.count > 1) { *idx = [found indexOfObject:view]; } else { *idx = NSNotFound; }

//static NSPredicate* _DTXAncestorPredicateForElement(DTXRecordedElement* element)
//{
//
//}

static NSString* DTXBestEffortAccessibilityIdentifierForView(UIView* view, UIAccessibilityTraits allowedLookupTraits, NSInteger* idx, DTXRecordedElement* ancestorElement)
{
	NSString* identifier = _DTXBestEffortAccessibilityIdentifierForView(view, allowedLookupTraits);
	
	if(identifier.length > 0)
	{
		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"accessibilityIdentifier == %@", identifier];
		
		NSArray* found = [UIView dtx_findViewsInAllWindowsPassingPredicate:predicate];
		IDX_IF_NEEDED;
	}
	
	return identifier;
}

static NSMutableString* _DTXBestEffortAccessibilityLabelForView(UIView* view)
{
	if([NSStringFromClass(view.class) hasSuffix:@"BarButton"])
	{
		//Short circuit for bar buttons—if they had no identifier, just return their accessilibity label.
		return [((UIButton*)view) accessibilityLabel].mutableCopy;
	}
	
	return [view accessibilityLabel].mutableCopy;
}

static NSMutableString* DTXBestEffortTextForView(UIView* view, NSInteger* idx, DTXRecordedElement* ancestorElement)
{
	NSMutableString* text = [view valueForKey:@"dtx_text"];
	
	if(text.length > 0)
	{
		NSArray* found = [UIView dtx_findViewsInAllWindowsPassingPredicate:[NSPredicate predicateWithFormat:@"dtx_text == %@", text]];
		IDX_IF_NEEDED;
	}
	
	return text;
}

static NSMutableString* DTXBestEffortAccessibilityLabelForView(UIView* view, NSInteger* idx, DTXRecordedElement* ancestorElement)
{
	NSMutableString* label = _DTXBestEffortAccessibilityLabelForView(view);
	
	if(label.length > 0)
	{
		NSArray* found = [UIView dtx_findViewsInAllWindowsPassingPredicate:[NSPredicate predicateWithFormat:@"accessibilityLabel == %@", label]];
		IDX_IF_NEEDED;
	}
	
	return label;
}

static NSMutableString* DTXBestEffortByClassForView(UIView* view, NSString* text, NSString* label, NSInteger* idx, DTXRecordedElement* ancestorElement)
{
	NSMutableString* rv = NSStringFromClass(view.class).mutableCopy;
	
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"self isKindOfClass: %@", view.class];
	if(text.length > 0)
	{
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [NSPredicate predicateWithFormat:@"dtx_text == %@", text]]];
	}
	else if(label.length > 0)
	{
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [NSPredicate predicateWithFormat:@"accessibilityLabel == %@", label]]];
	}
	
	NSArray* found = [UIView dtx_findViewsInAllWindowsPassingPredicate:predicate];
	IDX_IF_NEEDED;
	
	return rv;
}

static inline NSMutableString* DTXGetViewChainDescription(UIView* view)
{
	return [NSMutableString stringWithFormat:@"%p", view];
}

static NSMutableArray<NSMutableString*>* DTXGetSuperviewChain(UIView* view)
{
	NSMutableArray* rv = [NSMutableArray new];
	UIView* currView = view;
	while(currView != nil)
	{
		[rv addObject:DTXGetViewChainDescription(currView)];
		currView = currView.superview;
	}
	return rv;
}

@implementation DTXRecordedElement

+ (instancetype)elementWithView:(UIView*)view allowHierarchyTraversal:(BOOL)allowTraversal
{
	DTXRecordedElement* rv = [DTXRecordedElement new];
	
	UIAccessibilityTraits allowedLookupTraits = allowTraversal ? UIAccessibilityTraitButton : 0;
	
	DTXRecordedElement* ancestorElement = nil;
	if([view isKindOfClass:NSClassFromString(@"UISegment")])
	{
		UISegmentedControl* segmentControl = (id)view;
		while(segmentControl != nil && [segmentControl isKindOfClass:UISegmentedControl.class] == NO)
		{
			segmentControl = (id)segmentControl.superview;
		}
		
		ancestorElement = [self elementWithView:segmentControl allowHierarchyTraversal:NO];
	}
	else if([view.superview isKindOfClass:UITableViewCell.class])
	{
		ancestorElement = [self elementWithView:view.superview allowHierarchyTraversal:NO];
	}
	
	NSInteger byIdIdx = NSNotFound;
	NSString* byId = DTXBestEffortAccessibilityIdentifierForView(view, allowedLookupTraits, &byIdIdx, ancestorElement);
	
	NSInteger byTextIdx = NSNotFound;
	NSString* byText = DTXBestEffortTextForView(view, &byTextIdx, ancestorElement);
	
	NSInteger byLabelIdx = NSNotFound;
	NSString* byLabel = DTXBestEffortAccessibilityLabelForView(view, &byLabelIdx, ancestorElement);
	
	NSInteger byTypeIdx = NSNotFound;
	NSString* byType = nil;
	BOOL enforceByType = [view isKindOfClass:NSClassFromString(@"_UIButtonBarButton")];
	
	if(byId.length == 0 && (byLabel.length == 0 || byText.length == 0 || enforceByType == YES))
	{
		byType = DTXBestEffortByClassForView(view, byText, byLabel, &byTypeIdx, ancestorElement);
	}
	
	if(byId.length == 0 && byLabel.length == 0 && byType.length == 0 && byText.length == 0)
	{
		return nil;
	}
	
	if(byId.length > 0)
	{
		DTXRecordedElementMatcher* matcher = [DTXRecordedElementMatcher new];
		matcher.matcherType = DTXRecordedElementMatcherTypeById;
		matcher.matcherArgs = @[byId];
		
		rv.matchers = @[matcher];
		
		if(byIdIdx != NSNotFound && ancestorElement == nil)
		{
			rv.requiresAtIndex = YES;
			rv.atIndex = byIdIdx;
		}
	}
	else if(enforceByType == NO && byText.length > 0)
	{
		DTXRecordedElementMatcher* matcher = [DTXRecordedElementMatcher new];
		matcher.matcherType = DTXRecordedElementMatcherTypeByText;
		matcher.matcherArgs = @[byText];
		
		rv.matchers = @[matcher];
		
		if(byTextIdx != NSNotFound && ancestorElement == nil)
		{
			rv.requiresAtIndex = YES;
			rv.atIndex = byTextIdx;
		}
	}
	else if(enforceByType == NO && byLabel.length > 0)
	{
		DTXRecordedElementMatcher* matcher = [DTXRecordedElementMatcher new];
		matcher.matcherType = DTXRecordedElementMatcherTypeByLabel;
		matcher.matcherArgs = @[byLabel];
		
		rv.matchers = @[matcher];
		
		if(byLabelIdx != NSNotFound && ancestorElement == nil)
		{
			rv.requiresAtIndex = YES;
			rv.atIndex = byLabelIdx;
		}
	}
	else if(byType.length > 0)
	{
		DTXRecordedElementMatcher* matcher = [DTXRecordedElementMatcher new];
		matcher.matcherType = DTXRecordedElementMatcherTypeByType;
		matcher.matcherArgs = @[byType];
		
		NSMutableArray<DTXRecordedElementMatcher*>* matchers = [@[matcher] mutableCopy];
		
		if(byText.length > 0)
		{
			DTXRecordedElementMatcher* matcher = [DTXRecordedElementMatcher new];
			matcher.matcherType = DTXRecordedElementMatcherTypeByText;
			matcher.matcherArgs = @[byText];
			
			[matchers addObject:matcher];
		}
		else if(byLabel.length > 0)
		{
			DTXRecordedElementMatcher* matcher = [DTXRecordedElementMatcher new];
			matcher.matcherType = DTXRecordedElementMatcherTypeByLabel;
			matcher.matcherArgs = @[byLabel];
			
			[matchers addObject:matcher];
		}
		
		if(byTypeIdx != NSNotFound && ancestorElement == nil)
		{
			rv.requiresAtIndex = YES;
			rv.atIndex = byTypeIdx;
		}
		
		rv.matchers = matchers;
	}
	
	rv.viewClass = view.class;
	rv.chainDescription = DTXGetViewChainDescription(view);
	rv.superviewChain = DTXGetSuperviewChain(view);
	rv.ancestorElement = ancestorElement;
	
	return rv;
}

- (BOOL)isReferencingView:(UIView*)view;
{
	return [DTXGetViewChainDescription(view) isEqualToString:self.chainDescription];
}

- (BOOL)elementSuperviewChainContainsView:(UIView*)view
{
	return [self.superviewChain containsObject:DTXGetViewChainDescription(view)];
}

- (BOOL)elementSuperviewChainContainsElement:(DTXRecordedElement*)element;
{
	return [self.superviewChain containsObject:element.chainDescription];
}

- (BOOL)isEqualToElement:(DTXRecordedElement*)otherElement;
{
	return [self.chainDescription isEqualToString:otherElement.chainDescription];
}

- (NSString *)detoxDescription
{
	NSMutableString* rv = @"element(".mutableCopy;
	
	[rv appendString:[DTXRecordedElementMatcher detoxDescriptionForMatchers:self.matchers]];
	
	[rv appendString:@")"];
	
	if(self.ancestorElement)
	{
		[rv appendFormat:@".withAncestor(%@)", self.ancestorElement.detoxDescription];
	}
	
	if(self.requiresAtIndex)
	{
		[rv appendFormat:@".atIndex(%@)", @(self.atIndex)];
	}
	
	return rv;
}

- (NSString *)description
{
	return self.detoxDescription;
}

@end
