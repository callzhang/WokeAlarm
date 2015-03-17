//
//  Woke
//
//  Created by Zitao Xiong on 2/2/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWPerson+Woke.h"

typedef NS_ENUM(NSUInteger, EWAddFreindTableViewCellType) {
    EWAddFreindTableViewCellTypeAddFriend,
    EWAddFreindTableViewCellTypeInvite,
};

@interface EWAddFriendTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@property (nonatomic, strong) EWPerson *person;
@property (nonatomic, assign) EWAddFreindTableViewCellType type;

@property (nonatomic, copy) void (^ onInviteBlock)(void);
@end
