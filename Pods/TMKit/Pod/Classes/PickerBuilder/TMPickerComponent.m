//
//  TMPickerComponent.m
//  TMKit
//
//  Created by Zitao Xiong on 4/28/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMPickerComponent.h"
#import "TMPickerRow.h"
#import "TMPickerRow+Protected.h"
#import "TMPickerComponent+Protected.h"
#import "TMPickerBuilder.h"

@interface TMPickerComponent()
@property (nonatomic, strong) NSMutableArray *mutableRows;
@end

@implementation TMPickerComponent
- (instancetype)init {
    self = [super init];
    if (self) {
        self.mutableRows = [NSMutableArray array];
        self.rowHeightForComponent = 30;
        self.widthForComponent = 50;
    }
    return self;
}

- (void)insertObject:(TMPickerRow *)object inMutableRowsAtIndex:(NSUInteger)index {
    object.component = self;
    [self.mutableRows insertObject:object atIndex:index];
}

- (void)replaceObjectInMutableRowsAtIndex:(NSUInteger)index withObject:(TMPickerRow *)object {
    object.component = self;
    [self replaceObjectInMutableRowsAtIndex:index withObject:object];
}

- (void)removeObjectFromMutableRowsAtIndex:(NSUInteger)index {
    [self.mutableRows removeObjectAtIndex:index];
}

- (NSUInteger)numberOfRows {
    return self.mutableRows.count;
}

- (void)removeAllRors {
    [self.mutableRows removeAllObjects];
}

- (void)addRow:(TMPickerRow *)row {
    [self insertObject:row inMutableRowsAtIndex:self.mutableRows.count];
}

- (NSUInteger)indexOfRow:(TMPickerRow *)row {
    return [self.mutableRows indexOfObject:row];
}

- (NSInteger)component {
    return [self.pickerBuilder indexOfComponent:self];
}

- (TMPickerRow *)rowAtIndex:(NSUInteger)index {
    return [self.mutableRows objectAtIndex:index];
}
@end

@implementation TMPickerComponent (PickerRowAddition)

- (TMPickerRow *)addPickerRowWithTitle:(NSString *)title {
    TMPickerRow *row = [[TMPickerRow alloc] init];
    row.titleForRow = title;
    [self addRow:row];
    return row;
}

//- (TMPickerRow *)addPickerRowWithView:(UIView *)view {
//    TMPickerRow *row = [[TMPickerRow alloc] init];
//    row.viewForRow = view;
//    [self addRow:row];
//    return row;
//}

- (TMPickerRow *)addPickerRowWithAttributedString:(NSAttributedString *)attributedString {
    TMPickerRow *row = [[TMPickerRow alloc] init];
    row.attributedTitleForRow = attributedString;
    [self addRow:row];
    return row;
}

@end