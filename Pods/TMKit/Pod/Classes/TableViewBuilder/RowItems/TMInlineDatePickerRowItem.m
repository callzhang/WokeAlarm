//
//  TMInlineDatePickerRowItem.m
//  TMKit
//
//  Created by Zitao Xiong on 4/26/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMInlineDatePickerRowItem.h"
#import "TMInlineDatePickerTableViewCell.h"
#import "TMDatePickerRowItem.h"
@interface TMInlineDatePickerRowItem()<UIPickerViewDelegate>
@end

@implementation TMInlineDatePickerRowItem
- (instancetype)init {
    self = [super init];
    if (self) {
        self.heightForRow = 160;
    }
    return self;
}

+ (NSString *)reuseIdentifier {
    return NSStringFromClass([TMInlineDatePickerTableViewCell class]);
}

- (UITableViewCell *)cellForRow {
    TMInlineDatePickerTableViewCell *cell = (id)[super cellForRow];
    
    [self.configurator configureDatePicker:cell.datePicker];
    [cell.datePicker addTarget:self action:@selector(onValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    return cell;
}

- (void)didEndDisplayingCell:(TMInlineDatePickerTableViewCell *)cell {
    [super didEndDisplayingCell:cell];
    NSParameterAssert([cell isKindOfClass:[TMInlineDatePickerTableViewCell class]]);
    [cell.datePicker removeTarget:self action:@selector(onValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)onValueChanged:(UIDatePicker *)sender {
    [self.configurator updateFromDatePicker:sender];
    
    if (self.didValueChangedHandler) {
        self.didValueChangedHandler(self);
    }
}
@end
