//
//  TMPickerBuilder.m
//  TMKit
//
//  Created by Zitao Xiong on 4/28/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMPickerBuilder.h"
#import "TMPickerDataSource.h"
#import "TMPickerDelegate.h"
#import "TMPickerComponent.h"
#import "TMPickerComponent+Protected.h"
#import "_TMPickerNSStringDelegate.h"
#import "_TMPickerAttributeStringDelegate.h"
#import "_TMPickerUIViewDelegate.h"

@interface TMPickerBuilder()
@property (nonatomic, strong) TMPickerDataSource *datasource;
@property (nonatomic, strong) TMPickerDelegate *delegate;
@property (nonatomic, strong) NSMutableArray *mutableCompoents;
@property (nonatomic, assign) TMPickerType type;
@end

@implementation TMPickerBuilder
+ (instancetype)builderWithType:(TMPickerType)type pickerView:(UIPickerView *)pickerView {
    TMPickerBuilder *builder = [[self alloc] init];
    builder.mutableCompoents = [NSMutableArray array];
    builder.type = type;
    switch (builder.type) {
        case TMPickerBuilderString: {
            builder.delegate = [[_TMPickerNSStringDelegate alloc] initWithPickerBuilder:builder];
            break;
        }
        case TMPickerBuilderAttributedString: {
            builder.delegate = [[_TMPickerAttributeStringDelegate alloc] initWithPickerBuilder:builder];
            break;
        }
        case TMPickerBuilderUIView: {
            builder.delegate = [[_TMPickerUIViewDelegate alloc] initWithPickerBuilder:builder];
            break;
        }
        default: {
            break;
        }
    }
    builder.datasource = [[TMPickerDataSource alloc] initWithPickerBuilder:builder];
    builder.pickerView = pickerView;
    return builder;
}

+ (instancetype)builderWithType:(TMPickerType)type {
    return [self builderWithType:type pickerView:nil];
}

- (void)insertObject:(TMPickerComponent *)object inMutableCompoentsAtIndex:(NSUInteger)index {
    NSParameterAssert(self.type != TMPickerBuilderUnknown);
    object.pickerBuilder = self;
    [self.mutableCompoents insertObject:object atIndex:index];
}

- (void)replaceObjectInMutableCompoentsAtIndex:(NSUInteger)index withObject:(TMPickerComponent *)object {
    object.pickerBuilder = self;
    [self.mutableCompoents replaceObjectAtIndex:index withObject:object];
}

- (void)removeObjectFromMutableCompoentsAtIndex:(NSUInteger)index {
    [self.mutableCompoents removeObjectAtIndex:index];
}

- (void)removeAllComponent {
    [self.mutableCompoents removeAllObjects];
}

- (void)addComponent:(TMPickerComponent *)object {
    [self insertObject:object inMutableCompoentsAtIndex:self.mutableCompoents.count];
}

- (NSUInteger)numberOfComponent {
    return self.mutableCompoents.count;
}

- (NSUInteger)indexOfComponent:(TMPickerComponent *)object {
    return [self.mutableCompoents indexOfObject:object];
}

- (TMPickerComponent *)componentAtIndex:(NSUInteger)index {
    return [self.mutableCompoents objectAtIndex:index];
}

- (TMPickerRow *)rowAtIndex:(NSUInteger)index inComponent:(NSUInteger)component {
    TMPickerComponent *comp = [self componentAtIndex:component];
    return [comp rowAtIndex:index];
}

- (void)setPickerView:(UIPickerView *)pickerView {
    _pickerView = pickerView;
    _pickerView.delegate = self.delegate;
    _pickerView.dataSource = self.datasource;
}
@end
