//
//  Woke
//
//  Created by Zitao Xiong on 2/2/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWAddFriendTableViewCell.h"
#import "EWPersonManager.h"

@implementation EWAddFriendTableViewCell

- (void)awakeFromNib {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.profileImageView applyHexagonSoftMask];
    [self.inviteButton setImage:[ImagesCatalog wokeAddFriendsInviteButton] forState:UIControlStateNormal];
    [self.inviteButton setImage:[ImagesCatalog wokeAddFriendsInviteButtonHighlighted] forState:UIControlStateHighlighted];
    
    self.type = EWAddFreindTableViewCellTypeAddFriend;
    [self.inviteButton addTarget:self action:@selector(onInviteButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)updateWithFriendshipStatus:(NSNumber *)status {
    EWFriendshipStatus statusValue = [status integerValue];
    switch (statusValue) {
        case EWFriendshipStatusNone:
        case EWFriendshipStatusUnknown:
            [self.rightButton setImage:[ImagesCatalog wokeAddFriendsAddFriendButtonSmall] forState:UIControlStateNormal];
            [self.rightButton setImage:[ImagesCatalog wokeAddFriendsAddFriendButtonSmallHighlighted] forState:UIControlStateHighlighted];
            break;
        case EWFriendshipStatusSent:
            [self.rightButton setImage:[ImagesCatalog wokeAddFriendsFriendRequestSentButtonSmall] forState:UIControlStateNormal];
            [self.rightButton setImage:[ImagesCatalog wokeAddFriendsFriendRequestSentButtonSmallHighlighted] forState:UIControlStateHighlighted];
            break;
        case EWFriendshipStatusDenied:
        case EWFriendshipStatusFriended:
        case EWFriendshipStatusReceived:
            //TODO: missing states
            [self.rightButton setImage:[ImagesCatalog wokeAddFriendsFriendRequestSentButtonSmall] forState:UIControlStateNormal];
            [self.rightButton setImage:[ImagesCatalog wokeAddFriendsFriendRequestSentButtonSmallHighlighted] forState:UIControlStateHighlighted];
            break;
        default:
            break;
    }
}

- (void)setPerson:(EWPerson *)person {
    if (_person != person) {
        _person = person;
        self.profileImageView.image = person.profilePic;
        self.nameLabel.text = person.name;
        [self.profileImageView applyHexagonSoftMask];
        
        @weakify(self);
        [RACObserve(self.person, friendshipStatus) subscribeNext:^(NSNumber *status) {
            @strongify(self);
            DDLogVerbose(@"RAC friendship status: %@", status);
            [self updateWithFriendshipStatus:status];
        }];
    }
}

- (IBAction)onAddFriendButton:(id)sender {
    [[EWPersonManager shared] requestFriend:self.person
                                 completion:^(EWFriendshipStatus status, NSError *error) {
                                     DDLogVerbose(@"friend request sent, status changed to :%@", @(status));
                                     if (error) {
                                         DDLogError(@"got friend request sending error:%@", error);
                                     }
                                     [self updateWithFriendshipStatus:@(status)];
                                 }];
}

- (void)setType:(EWAddFreindTableViewCellType)type {
    _type = type;
    if (type == EWAddFreindTableViewCellTypeAddFriend) {
        self.rightButton.hidden = NO;
        self.inviteButton.hidden = YES;
    }
    else if (type == EWAddFreindTableViewCellTypeInvite) {
        self.rightButton.hidden = YES;
        self.inviteButton.hidden = NO;
    }
    else {
        DDLogError(@"button type %@ not supported", @(type));
    }
}

- (void)onInviteButton:(id)sender {
    if (self.onInviteBlock) {
        self.onInviteBlock();
    }
}
@end

