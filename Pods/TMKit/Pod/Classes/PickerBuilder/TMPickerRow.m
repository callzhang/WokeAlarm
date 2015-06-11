//
//  TMPickerRow.m
//  TMKit
//
//  Created by Zitao Xiong on 4/28/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMPickerRow.h"
#import "TMPickerComponent.h"
#import "TMPickerRow+Protected.h"

@interface TMPickerRow ()
/*
 * in TMPickerRow+Protected.h
 */
@end

@implementation TMPickerRow
- (void)didSelectRow {
    if (self.didSelectPickerRowHandler) {
        self.didSelectPickerRowHandler(self);
    }
}

- (NSInteger)row {
    return [self.component indexOfRow:self];
}

- (UIView *)viewForRowWithReusingView:(id)view {
    if (self.viewForRowWithReusingViewHandler) {
        return self.viewForRowWithReusingViewHandler(view);
    }
    else {
        return view;
    }
}
@end
