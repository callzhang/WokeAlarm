//
//  TMPickerViewRowItem.m
//  TMKit
//
//  Created by Zitao Xiong on 4/14/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMPickerViewRowItem.h"

@implementation TMPickerViewRowItem
+ (NSString *)reuseIdentifier {
    return @"TMPickerViewTableViewCell";
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.heightForRow = 162;
    }
    return self;
}
@end
