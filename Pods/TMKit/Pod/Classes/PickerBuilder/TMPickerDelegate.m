//
//  TMPickerDelegate.m
//  TMKit
//
//  Created by Zitao Xiong on 4/28/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMPickerDelegate.h"
#import "TMPickerBuilder.h"
#import "TMPickerComponent.h"
#import "TMPickerRow.h"
#import "TMPickerDelegate+Protected.h"

@interface TMPickerDelegate ()
/*
 * see TMPickerDelegate+Protected.h
 */
@end
@implementation TMPickerDelegate

- (instancetype)initWithPickerBuilder:(TMPickerBuilder *)builder {
    self = [super init];
    if (self) {
        self.pickerBuilder = builder;
    }
    
    return self;
}


#pragma mark - UIPickerViewDelegate
// returns width of column and height of row for each component.
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    TMPickerComponent *pickerComponent = [self.pickerBuilder componentAtIndex:component];
    return pickerComponent.widthForComponent;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    if ((NSUInteger) component >= self.pickerBuilder.numberOfComponent) {
        //TODO: why hitting here?
        return 0;
    }
    TMPickerComponent *pickerComponent = [self.pickerBuilder componentAtIndex:component];
    return pickerComponent.rowHeightForComponent;
}
/*
 * priority => UIView > NSAttributedString > NSString
 * following methods are implemented in _TMPickerUIViewDelegate, _TMPickerNSStringDelegate, and _TMPickerAttributedStringDelegate
 *
 *
// these methods return either a plain NSString, a NSAttributedString, or a view (e.g UILabel) to display the row for the component.
// for the view versions, we cache any hidden and thus unused views and pass them back for reuse.
// If you return back a different object, the old one will be released. the view will be centered in the row rect

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    TMPickerRow *pickerRow = [self.pickerBuilder rowAtIndex:row inComponent:component];
    return pickerRow.titleForRow;
}

// attributed title is favored if both methods are implemented
- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component NS_AVAILABLE_IOS(6_0) {
    TMPickerRow *pickerRow = [self.pickerBuilder rowAtIndex:row inComponent:component];
    return pickerRow.attributedTitleForRow;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    TMPickerRow *pickerRow = [self.pickerBuilder rowAtIndex:row inComponent:component];
    return pickerRow.viewForRow;
}
 */

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    TMPickerRow *pickerRow = [self.pickerBuilder rowAtIndex:row inComponent:component];
    [pickerRow didSelectRow];
}
@end
