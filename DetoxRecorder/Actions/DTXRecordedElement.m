//
//  DTXRecordedElement.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "DTXRecordedElement.h"
#import "UIView+DTXDescendants.h"
#import "NSString+DTXQuotedStringForJS.h"

DTXRecordedElementMatcherType const DTXRecordedElementMatcherTypeById = @"by.id";
DTXRecordedElementMatcherType const DTXRecordedElementMatcherTypeByType = @"by.type";
DTXRecordedElementMatcherType const DTXRecordedElementMatcherTypeByLabel = @"by.label";

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
			return [obj _dtx_quotedStringRepresentationForJS];
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

@property (nonatomic, strong) Class viewClass;
@property (nonatomic, strong) NSString* chainDescription;
@property (nonatomic, strong) NSArray<NSString*>* superviewChain;

@end

static NSMutableString* _DTXBestEffortAccessibilityIdentifierForView(UIView* view, UIAccessibilityTraits allowedLookupTraits)
{
	if(view.accessibilityIdentifier.length > 0)
	{
		return view.accessibilityIdentifier.mutableCopy;
	}
	
	if([NSStringFromClass(view.class) hasSuffix:@"BarButton"])
	{
		//For bar buttons with no identifiers, quickly fail. Other logic will take the title instead of an identifier.
		return nil;
	}
	
	if([view isKindOfClass:NSClassFromString(@"RCTCustomScrollView")])
	{
		return view.superview.accessibilityIdentifier.mutableCopy;
	}
	
	UIView* currView = view;
	while(allowedLookupTraits != 0 && currView != nil && currView.accessibilityIdentifier.length == 0 && (currView.accessibilityTraits & allowedLookupTraits) == 0)
	{
		currView = currView.superview;
	}
	
	return currView.accessibilityIdentifier.mutableCopy;
}

#define IDX_IF_NEEDED if(found.count > 1) { *idx = [found indexOfObject:view]; } else { *idx = NSNotFound; }

static NSMutableString* DTXBestEffortAccessibilityIdentifierForView(UIView* view, UIAccessibilityTraits allowedLookupTraits, NSInteger* idx)
{
	NSMutableString* identifier = _DTXBestEffortAccessibilityIdentifierForView(view, allowedLookupTraits);
	
	if(identifier.length > 0)
	{
		NSArray* found = [UIView dtx_findViewsInHierarchy:view.window passingPredicate:[NSPredicate predicateWithFormat:@"accessibilityIdentifier == %@", identifier]];
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

static NSMutableString* DTXBestEffortAccessibilityLabelForView(UIView* view, NSInteger* idx)
{
	NSMutableString* label = _DTXBestEffortAccessibilityLabelForView(view);
	
	if(label.length > 0)
	{
		NSArray* found = [UIView dtx_findViewsInHierarchy:view.window passingPredicate:[NSPredicate predicateWithFormat:@"accessibilityLabel == %@", label]];
		IDX_IF_NEEDED;
	}
	
	return label;
}

//static

static NSMutableString* DTXBestEffortByClassForView(UIView* view, NSString* label, NSInteger* idx)
{
	NSMutableString* rv = NSStringFromClass(view.class).mutableCopy;
	
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"self isKindOfClass: %@", view.class];
	if(label.length > 0)
	{
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [NSPredicate predicateWithFormat:@"accessibilityLabel == %@", label]]];
	}
	
	NSArray* found = [UIView dtx_findViewsInHierarchy:view.window passingPredicate:predicate];
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
	
	NSInteger byTypeIdx = NSNotFound;
	NSString* byId = DTXBestEffortAccessibilityIdentifierForView(view, allowedLookupTraits, &byTypeIdx);
	NSString* byLabel = DTXBestEffortAccessibilityLabelForView(view, &byTypeIdx);
	NSString* byType = nil;
	BOOL enforceByType = [view isKindOfClass:NSClassFromString(@"_UIButtonBarButton")];
	
	if(byId.length == 0 && (byLabel.length == 0 || enforceByType == YES))
	{
		byType = DTXBestEffortByClassForView(view, byLabel, &byTypeIdx);
	}
	
	if(byId.length == 0 && byLabel.length == 0 && byType.length == 0)
	{
		return nil;
	}
	
	if(byId.length > 0)
	{
		DTXRecordedElementMatcher* matcher = [DTXRecordedElementMatcher new];
		matcher.matcherType = DTXRecordedElementMatcherTypeById;
		matcher.matcherArgs = @[byId];
		
		rv.matchers = @[matcher];
	}
	else if(enforceByType == NO && byLabel.length > 0)
	{
		DTXRecordedElementMatcher* matcher = [DTXRecordedElementMatcher new];
		matcher.matcherType = DTXRecordedElementMatcherTypeByLabel;
		matcher.matcherArgs = @[byLabel];
		
		rv.matchers = @[matcher];
	}
	else if(byType.length > 0)
	{
		DTXRecordedElementMatcher* matcher = [DTXRecordedElementMatcher new];
		matcher.matcherType = DTXRecordedElementMatcherTypeByType;
		matcher.matcherArgs = @[byType];
		
		NSMutableArray<DTXRecordedElementMatcher*>* matchers = [@[matcher] mutableCopy];
		
		if(byLabel.length > 0)
		{
			DTXRecordedElementMatcher* matcher = [DTXRecordedElementMatcher new];
			matcher.matcherType = DTXRecordedElementMatcherTypeByLabel;
			matcher.matcherArgs = @[byLabel];
			
			[matchers addObject:matcher];
		}
		
		rv.matchers = matchers;
	}
	
	if(byTypeIdx != NSNotFound)
	{
		rv.requiresAtIndex = YES;
		rv.atIndex = byTypeIdx;
	}
	
	rv.viewClass = view.class;
	rv.chainDescription = DTXGetViewChainDescription(view);
	rv.superviewChain = DTXGetSuperviewChain(view);
	
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
