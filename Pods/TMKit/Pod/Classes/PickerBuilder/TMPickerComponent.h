//
//  TMPickerComponent.h
//  TMKit
//
//  Created by Zitao Xiong on 4/28/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TMPickerRow, TMPickerBuilder;
@interface TMPickerComponent : NSObject
@property (nonatomic, assign) CGFloat widthForComponent;
@property (nonatomic, assign) CGFloat rowHeightForComponent;
@property (nonatomic, weak, readonly) TMPickerBuilder *pickerBuilder;

- (void)insertObject:(TMPickerRow *)object inMutableRowsAtIndex:(NSUInteger)index;
- (void)replaceObjectInMutableRowsAtIndex:(NSUInteger)index withObject:(TMPickerRow *)object;
- (void)removeObjectFromMutableRowsAtIndex:(NSUInteger)index;
- (void)addRow:(TMPickerRow *)row;

- (NSUInteger)numberOfRows;

- (void)removeAllRors;

- (NSUInteger)indexOfRow:(TMPickerRow *)row;
// index of component
- (NSInteger)component;

- (TMPickerRow *)rowAtIndex:(NSUInteger)index;
@end

@interface TMPickerComponent (PickerRowAddition)
- (TMPickerRow *)addPickerRowWithTitle:(NSString *)title;
//- (TMPickerRow *)addPickerRowWithView:(UIView *)view;
- (TMPickerRow *)addPickerRowWithAttributedString:(NSAttributedString *)attributedString;
@end