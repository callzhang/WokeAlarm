//
//  EWVoiceSectionHeaderRowItem.m
//  Woke
//
//  Created by Zitao Xiong on 6/8/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWVoiceSectionHeaderRowItem.h"
#import "EWVoiceSectionHeaderTableViewCell.h"
@interface EWVoiceSectionHeaderRowItem ()
@property (nonatomic, strong) NSMutableArray *relatedRowItems;
@end

@implementation EWVoiceSectionHeaderRowItem
+ (NSString * __nonnull)reuseIdentifier {
    return NSStringFromClass([EWVoiceSectionHeaderTableViewCell class]);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.heightForRow = 29;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.relatedRowItems = [NSMutableArray array];
    }
    return self;
}

- (id __nonnull)cellForRow {
    EWVoiceSectionHeaderTableViewCell *cell = [super cellForRow];
    cell.cellTextLabel.text = self.text;
    cell.cellDetailTextLabel.text = self.detailText;
    return cell;
}

- (void)addRelatedRowItem:(TMRowItem *)rowItem {
    [self.relatedRowItems addObject:rowItem];
}

- (void)removeRelatedRowItem:(TMRowItem *)rowItem {
    [self.relatedRowItems removeObject:rowItem];
    if (self.relatedRowItems.count == 0) {
        [self deleteRowWithAnimation:UITableViewRowAnimationFade];
    }
}
@end
