//
//  EWSentVoiceRowItem.m
//  Woke
//
//  Created by Zitao Xiong on 6/8/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWSentVoiceRowItem.h"
#import "EWSentVoiceTableViewCell.h"

@implementation EWSentVoiceRowItem
+ (NSString * __nonnull)reuseIdentifier {
    return NSStringFromClass([EWSentVoiceTableViewCell class]);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.heightForRow = 70;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (id __nonnull)cellForRow {
    EWSentVoiceTableViewCell *cell = [super cellForRow];
    cell.media = self.media;
    return cell;
}
@end
