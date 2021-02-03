//
//  DTXRecordedElement.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

typedef NSString* DTXRecordedElementMatcherType NS_TYPED_ENUM;

extern DTXRecordedElementMatcherType const DTXRecordedElementMatcherTypeById;
extern DTXRecordedElementMatcherType const DTXRecordedElementMatcherTypeByType;
extern DTXRecordedElementMatcherType const DTXRecordedElementMatcherTypeByLabel;
extern DTXRecordedElementMatcherType const DTXRecordedElementMatcherTypeByText;

@interface DTXRecordedElementMatcher : NSObject

@property (nonatomic, strong, readonly) DTXRecordedElementMatcherType matcherType;
@property (nonatomic, strong, readonly) NSArray* matcherArgs;

- (NSString*)detoxDescription;
+ (NSString*)detoxDescriptionForMatchers:(NSArray<DTXRecordedElementMatcher*>*)matchers;

@end

@interface DTXRecordedElement : NSObject

@property (nonatomic, readonly, copy) NSArray<DTXRecordedElementMatcher*>* matchers;
@property (nonatomic, readonly) BOOL requiresAtIndex;
@property (nonatomic, readonly) NSInteger atIndex;
@property (nonatomic, readonly) DTXRecordedElement* ancestorElement;

+ (nullable instancetype)elementWithView:(UIView*)view allowHierarchyTraversal:(BOOL)allowHierarchyTraversal;

- (BOOL)isEqualToElement:(DTXRecordedElement*)otherElement;
- (BOOL)isReferencingView:(UIView*)view;
- (BOOL)elementSuperviewChainContainsView:(UIView*)view;
- (BOOL)elementSuperviewChainContainsElement:(DTXRecordedElement*)element;

- (NSString*)detoxDescription;

@end

NS_ASSUME_NONNULL_END
