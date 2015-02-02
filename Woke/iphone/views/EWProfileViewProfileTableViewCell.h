//
//  EWProfileViewProfileTableViewCell.h
//  Woke
//
//  Created by Zitao Xiong on 2/1/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EWPerson;
@interface EWProfileViewProfileTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *profileImageButton;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextAlarmButton;
@property (weak, nonatomic) IBOutlet UILabel *statementLabel;
@property (weak, nonatomic) IBOutlet UIButton *addFriendButton;

@property (nonatomic, strong) EWPerson *person;
@end
