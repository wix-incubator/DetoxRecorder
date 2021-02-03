//
//  DTXAppleInternals.h
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 5/6/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

@interface UIScrollView ()

-(void)_updatePanGesture;

@end

@interface UIGestureRecognizer ()

- (NSSet<UIEvent*>*)_activeEvents;

@end

@interface UITableView ()

- (UIView*)_containerView;
- (UIPickerView*)_pickerView;

@end

@interface UIPickerView ()

- (UITableView*)tableViewForColumn:(NSInteger)arg1;

@end
