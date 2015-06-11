//
//  _TMPickerAttributeStringDelegate.m
//  TMKit
//
//  Created by Zitao Xiong on 4/29/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "_TMPickerAttributeStringDelegate.h"
#import "TMPickerDelegate+Protected.h"
#import "TMPickerRow.h"
#import "TMPickerBuilder.h"

@implementation _TMPickerAttributeStringDelegate
- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component NS_AVAILABLE_IOS(6_0) {
    TMPickerRow *pickerRow = [self.pickerBuilder rowAtIndex:row inComponent:component];
    return pickerRow.attributedTitleForRow;
}
@end
