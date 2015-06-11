//
//  TMInlinePickerRowItem.m
//  TMKit
//
//  Created by Zitao Xiong on 4/28/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMInlinePickerRowItem.h"
#import "TMInlinePickerTableViewCell.h"
#import "TMPickerBuilder.h"
#import "TMPickerComponent.h"
#import "TMPickerRow.h"
#import "TMKit.h"


@interface TMInlinePickerRowItem()
@end

@implementation TMInlinePickerRowItem
+ (NSString *)reuseIdentifier {
    return NSStringFromClass([TMInlinePickerTableViewCell class]);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.heightForRow = 160;
    }
    return self;
}

- (UITableViewCell *)cellForRow {
    TMInlinePickerTableViewCell *cell = (id)[super cellForRow];
    self.pickerBuilder.pickerView = cell.pickerView;
    return cell;
}

- (void)didEndDisplayingCell:(TMInlinePickerTableViewCell *)cell {
    [super didEndDisplayingCell:cell];
    cell.pickerView.dataSource = nil;
    cell.pickerView.delegate = nil;
}

- (instancetype)initWithTitles:(NSArray *)titles {
    self = [self init];
    if (self) {
        self.pickerBuilder = [TMPickerBuilder builderWithType:TMPickerBuilderString];
        for (NSArray *title in titles) {
            NSParameterAssert([title isKindOfClass:[NSArray class]]);
            TMPickerComponent *component = [[TMPickerComponent alloc] init];
            component.widthForComponent = 100;
            [self.pickerBuilder addComponent:component];
            for (NSString *text in title) {
                NSParameterAssert([text isKindOfClass:[NSString class]]);
                TMPickerRow *pickerRow = [component addPickerRowWithTitle:text];
                @weakify(self);
                [pickerRow setDidSelectPickerRowHandler:^(TMPickerRow *pickerRow) {
                   @strongify(self);
                    if (self.didSelectPickerRowHandler) {
                        self.didSelectPickerRowHandler(self, pickerRow);
                    }
                }];
            }
        }
    }
    return self;
}
@end
