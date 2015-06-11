//
//  EWSentVoiceRowItem.m
//  Woke
//
//  Created by Zitao Xiong on 6/8/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWVoiceRowItem.h"
#import "EWVoiceTableViewCell.h"
#import "TMTableViewBuilder.h"
#import "TMSectionItem.h"

@implementation EWVoiceRowItem
+ (NSString * __nonnull)reuseIdentifier {
    return NSStringFromClass([EWVoiceTableViewCell class]);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.heightForRow = 70;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.editingStyleForRow = UITableViewCellEditingStyleDelete;
        self.canEditRow = YES;
    }
    return self;
}

- (id __nonnull)cellForRow {
    EWVoiceTableViewCell *cell = [super cellForRow];
    cell.media = self.media;
    return cell;
}

- (NSArray * __nullable)editActionsForRow {
    return @[[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        if (self.onDeleteRowHandler) {
            self.onDeleteRowHandler(self);
        }
    }]];
}

@end
