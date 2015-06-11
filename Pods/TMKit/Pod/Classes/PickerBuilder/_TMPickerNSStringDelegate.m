//
//  _TMPickerNSStringDelegate.m
//  TMKit
//
//  Created by Zitao Xiong on 4/29/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "_TMPickerNSStringDelegate.h"
#import "TMPickerDelegate+Protected.h"
#import "TMPickerRow.h"
#import "TMPickerBuilder.h"

@implementation _TMPickerNSStringDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    TMPickerRow *pickerRow = [self.pickerBuilder rowAtIndex:row inComponent:component];
    return pickerRow.titleForRow;
}
@end
