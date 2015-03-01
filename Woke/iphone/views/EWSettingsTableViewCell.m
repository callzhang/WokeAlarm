//
//  EWSettingsTableViewCell.m
//  Woke
//
//  Created by Zitao Xiong on 2/28/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWSettingsTableViewCell.h"

@interface EWSettingsTableViewCell ()

@end

@implementation EWSettingsTableViewCell
- (void)awakeFromNib {
    [super awakeFromNib];
    self.contentView.backgroundColor = [UIColor clearColor];
}

- (void)setType:(EWSettingsTableViewCellType)type {
    _type = type;
    
    self.rightLabel.hidden = YES;
    self.rightArrowImageView.hidden = YES;
    self.sevenSwitch.hidden = YES;
    
    switch (_type) {
        case EWSettingsTableViewCellTypeStandard:
        {
            self.rightArrowImageView.hidden = NO;
            break;
        }
        case EWSettingsTableViewCellTypeDetail:
        {
            self.rightLabel.hidden = NO;
            break;
        }
        case EWSettingsTableViewCellTypeSwitch:
        {
            self.sevenSwitch.hidden = NO;
            break;
        }
            
        default:
            break;
    }
}
@end
