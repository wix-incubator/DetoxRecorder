//
//  DTXRecordedAction-Private.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "DTXRecordedAction.h"

@interface DTXRecordedAction ()

@property (nonatomic, strong, readwrite) DTXRecordedElement* element;

@property (nonatomic, readwrite, strong) DTXRecordedActionType actionType;
@property (nonatomic, readwrite, strong) NSArray* actionArgs;

@property (nonatomic, readwrite) BOOL allowsUpdates;

@property (nonatomic, readwrite, getter=isCancelled) BOOL cancelled;

- (instancetype)initWithElementView:(UIView*)view allowHierarchyTraversal:(BOOL)allowHierarchyTraversal;

@end
