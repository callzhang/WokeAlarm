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
        [_notification getParseObjectInBackgroundWithCompletion:^(PFObject *object, NSError *error) {
            self.time.text = [object.createdAt.timeElapsedString stringByAppendingString:@" ago"];
            _notification.createdAt = object.createdAt;
            [_notification saveToLocal];
        }];
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
        NSError *error;
        EWPerson *sender = [[EWPersonManager sharedInstance] getPersonByServerID:personID error:&error];
		__block EWPerson *localPerson;
		[mainContext MR_saveWithBlock:^(NSManagedObjectContext *localContext) {
			localPerson = (EWPerson *)[EWSync findObjectWithClass:[[EWPerson class] serverClassName] withID:personID inContext:localContext error:nil];
			//NSParameterAssert(localPerson);
		} completion:^(BOOL contextDidSave, NSError *error) {
			EWPerson *sender = [localPerson MR_inContext:mainContext];
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
		}];
		
        //TODO: add "xxx ago" times
        if([type isEqualToString:kNotificationTypeFriendRequest]){
            self.detail.text = [NSString stringWithFormat:@"%@ has sent you a friend request", sender.name];
        }
        else if([type isEqualToString:kNotificationTypeFriendAccepted]){
            self.detail.text = [NSString stringWithFormat:@"%@ has accepted your friend request", sender.name];
        }
        else if ([type isEqualToString:kNotificationTypeNewMedia]){
            self.detail.text = @"You have received voice(s) for next wake up.";
        }else if ([type isEqualToString:kNotificationTypeNewUser]){
            self.detail.text = [NSString stringWithFormat:@"Your friend %@ just joined Woke", sender.name];
        }
    }
    
    if (notification.completed) {
        self.unreadDotImageView.hidden = YES;
    }
    else{
        self.unreadDotImageView.hidden = NO;
    }
    
    [self.profilePic applyHexagonSoftMask];
}
@end
