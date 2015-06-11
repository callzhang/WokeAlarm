//
//  TMPickerBuilder.h
//  TMKit
//
//  Created by Zitao Xiong on 4/28/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//
@import UIKit;

@class TMPickerComponent, TMPickerRow;

typedef NS_ENUM(NSUInteger, TMPickerType) {
    TMPickerBuilderUnknown,
    TMPickerBuilderString,
    TMPickerBuilderAttributedString,
    TMPickerBuilderUIView,
};

@interface TMPickerBuilder : NSObject
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, assign, readonly) TMPickerType type;
+ (instancetype)builderWithType:(TMPickerType)type;
+ (instancetype)builderWithType:(TMPickerType)type pickerView:(UIPickerView *)pickerView;
    
- (NSUInteger)numberOfComponent;
- (void)addComponent:(TMPickerComponent *)object;
- (void)removeAllComponent;

- (NSUInteger)indexOfComponent:(TMPickerComponent *)object;

- (TMPickerComponent *)componentAtIndex:(NSUInteger)index;
- (TMPickerRow *)rowAtIndex:(NSUInteger)index inComponent:(NSUInteger)component;


- (void)removeObjectFromMutableCompoentsAtIndex:(NSUInteger)index;
- (void)replaceObjectInMutableCompoentsAtIndex:(NSUInteger)index withObject:(TMPickerComponent *)object;
- (void)insertObject:(TMPickerComponent *)object inMutableCompoentsAtIndex:(NSUInteger)index;
@end
