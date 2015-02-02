//
//  EWFriendsViewTableViewCell.m
//  Woke
//
//  Created by Zitao Xiong on 2/1/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWFriendsViewTableViewCell.h"
#import "EWPerson.h"

@implementation EWFriendsViewTableViewCell

- (void)awakeFromNib {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
}


- (void)setPerson:(EWPerson *)person {
    if (_person != person) {
        _person = person;
        
        self.profileImageView.image = person.profilePic;
        self.nameLabel.text = person.name;
        [self.profileImageView applyHexagonSoftMask];
    }
}
@end
