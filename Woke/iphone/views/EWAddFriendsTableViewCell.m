//
//  EWAddFriendsTableViewCell.m
//  Woke
//
//  Created by Zitao Xiong on 2/2/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWAddFriendsTableViewCell.h"

@implementation EWAddFriendsTableViewCell

- (void)awakeFromNib {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
}

- (void)setPerson:(EWPerson *)person {
    if (_person != person) {
        _person = person;
        self.imageView.image = person.profilePic;
        self.nameLabel.text = person.name;
        [self.imageView applyHexagonSoftMask];
    }
}

- (IBAction)onAddFriendButton:(id)sender {
    
}
@end
