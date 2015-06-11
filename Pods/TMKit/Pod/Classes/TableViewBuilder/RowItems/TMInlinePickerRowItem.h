//
//  TMInlinePickerRowItem.h
//  TMKit
//
//  Created by Zitao Xiong on 4/28/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMRowItem.h"

@class TMPickerBuilder, TMPickerRow, TMPickerRowItem;
@interface TMInlinePickerRowItem : TMRowItem
@property (nonatomic, weak) TMPickerRowItem *pickerRowItem;
@property (nonatomic, strong) TMPickerBuilder *pickerBuilder;

@property (nonatomic, copy) void (^didSelectPickerRowHandler) (id rowItem, TMPickerRow *pickerRow);
- (void)setDidSelectPickerRowHandler:(void (^)(id rowItem, TMPickerRow *pickerRow))didSelectPickerRowHandler;

// @[[@"title", @"title2"]]
- (instancetype)initWithTitles:(NSArray *)titles;
@end
