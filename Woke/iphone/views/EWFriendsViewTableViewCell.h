//
//  EWFriendsViewTableViewCell.h
//  Woke
//
//  Created by Zitao Xiong on 2/1/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EWPerson;
@interface EWFriendsViewTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) EWPerson *person;

@end
