//
//  EWSettingsTableViewCell.h
//  Woke
//
//  Created by Zitao Xiong on 2/28/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SevenSwitch.h"

typedef NS_ENUM(NSUInteger, EWSettingsTableViewCellType) {
    EWSettingsTableViewCellTypeStandard,
    EWSettingsTableViewCellTypeDetail,
    EWSettingsTableViewCellTypeSwitch,
};

@interface EWSettingsTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *leftLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightLabel;
@property (weak, nonatomic) IBOutlet UIImageView *rightArrowImageView;
@property (weak, nonatomic) IBOutlet SevenSwitch *sevenSwitch;

@property (nonatomic, assign) EWSettingsTableViewCellType type;
@end
