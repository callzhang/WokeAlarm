//
//  EWAlertTableViewCell.m
//  Woke
//
//  Created by Zitao Xiong on 12/7/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWAlarmTableViewCell.h"

@implementation EWAlarmTableViewCell

- (void)awakeFromNib {
    self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.04];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
