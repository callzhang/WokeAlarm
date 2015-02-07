//
//  EWNotificationCell.m
//  Woke
//
//  Created by Lee on 7/3/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWNotificationCell.h"
#import "EWNotification.h"
#import "EWPerson.h"
#import "EWUIUtil.h"
#import "EWPersonManager.h"
#import "UIView+Layout.h"

@interface EWNotificationCell()

@end

@implementation EWNotificationCell
- (void)awakeFromNib {
    [super awakeFromNib];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.backgroundColor = [UIColor clearColor];
}

- (void)setNotification:(EWNotification *)notification{
    if (_notification == notification) {
        return;
    }
    _notification = notification;

    //time
    if (notification.createdAt) {
        self.time.text = [notification.createdAt.timeElapsedString stringByAppendingString:@" ago"];
    }
    else{
		__block EWNotification *blockNotification = _notification;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            PFObject *PO = blockNotification.parseObject;
            dispatch_async(dispatch_get_main_queue(), ^{
                blockNotification.createdAt = PO.createdAt;
                self.time.text = [blockNotification.createdAt.timeElapsedString stringByAppendingString:@" ago"];
            });
        });
        
    }
    
    //type
    NSString *type = notification.type;
    if ([type isEqualToString:kNotificationTypeSystemNotice]) {
        self.profilePic.image = nil;
        self.profilePic.hidden = YES;
        
        NSString *title = notification.userInfo[@"title"];
        NSString *body = notification.userInfo[@"content"];
        NSString *link = notification.userInfo[@"link"];
        
        self.detail.text = [title stringByAppendingString:[NSString stringWithFormat:@"\n%@\n%@", body, link]];
    }
    else{
        //kNotificationTypeNextTaskHasMedia
        //kNotificationTypeFriendRequest
        //kNotificationTypeFriendAccepted
        
        NSString *personID = notification.sender;
        EWPerson *sender = [[EWPersonManager sharedInstance] getPersonByServerID:personID];
        self.profilePic.hidden = NO;
        if (sender.profilePic) {
            self.profilePic.image = sender.profilePic;
        }
        else{
            //download
            [sender refreshShallowWithCompletion:^(NSError *error) {
                self.profilePic.image = sender.profilePic;
            }];
        }
        //TODO: add "xxx ago" times
        if([type isEqualToString:kNotificationTypeFriendRequest]){
            self.detail.text = [NSString stringWithFormat:@"%@ has sent you a friend request", sender.name];
        }
        else if([type isEqualToString:kNotificationTypeFriendAccepted]){
            self.detail.text = [NSString stringWithFormat:@"%@ has accepted your friend request", sender.name];
        }
        else if (kNotificationTypeNewMedia){
            self.detail.text = @"You have received voice(s) for next wake up.";
        }
    }
    
    if (notification.completed) {
        self.unreadDotImageView.hidden = YES;
    }
    else{
        self.unreadDotImageView.hidden = NO;
    }
    
}
@end
