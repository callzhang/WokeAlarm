//
//  _TMPickerUIViewDelegate.m
//  TMKit
//
//  Created by Zitao Xiong on 4/29/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "_TMPickerUIViewDelegate.h"
#import "TMPickerDelegate+Protected.h"
#import "TMPickerRow.h"
#import "TMPickerBuilder.h"

@implementation _TMPickerUIViewDelegate
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    TMPickerRow *pickerRow = [self.pickerBuilder rowAtIndex:row inComponent:component];
    return [pickerRow viewForRowWithReusingView:view];
}

@end
