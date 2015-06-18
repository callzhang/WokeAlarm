//
//  EWSettingRowItem.m
//  Woke
//
//  Created by Zitao Xiong on 6/17/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWSettingRowItem.h"
#import "EWSettingTableViewCell.h"

@implementation EWSettingRowItem
+ (NSString *)reuseIdentifier {
    return NSStringFromClass([EWSettingTableViewCell class]);
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (EWSettingTableViewCell *)cellForRow {
    EWSettingTableViewCell *cell = [super cellForRow];
    return cell;
}
@end
