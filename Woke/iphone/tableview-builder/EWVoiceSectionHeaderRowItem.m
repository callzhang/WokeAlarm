//
//  EWVoiceSectionHeaderRowItem.m
//  Woke
//
//  Created by Zitao Xiong on 6/8/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWVoiceSectionHeaderRowItem.h"
#import "EWVoiceSectionHeaderTableViewCell.h"

@implementation EWVoiceSectionHeaderRowItem
+ (NSString * __nonnull)reuseIdentifier {
    return NSStringFromClass([EWVoiceSectionHeaderTableViewCell class]);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.heightForRow = 29;
    }
    return self;
}

- (id __nonnull)cellForRow {
    EWVoiceSectionHeaderTableViewCell *cell = [super cellForRow];
    cell.cellTextLabel.text = self.text;
    cell.cellDetailTextLabel.text = self.detailText;
    return cell;
}
@end
