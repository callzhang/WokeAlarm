//
//  EWAlertTableViewCell.m
//  Woke
//
//  Created by Zitao Xiong on 12/7/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWAlarmTableViewCell.h"
#import "EWAlarm.h"
#import "SevenSwitch.h"
@interface EWAlarmTableViewCell()
@property (weak, nonatomic) IBOutlet UIImageView *nextImageView;
@end

@implementation EWAlarmTableViewCell

- (void)awakeFromNib {
}

- (void)setNextAlarm:(BOOL)nextAlarm {
    _nextAlarm = nextAlarm;
    if (_nextAlarm) {
        self.nextImageView.hidden = NO;
    }
    else {
        self.nextImageView.hidden = YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onPlusButton:(id)sender {
    self.alarm.time = [self.alarm.time mt_dateByAddingYears:0 months:0 weeks:0 days:0 hours:0 minutes:10 seconds:0];
}

- (IBAction)onMinusButton:(id)sender {
    self.alarm.time = [self.alarm.time mt_dateByAddingYears:0 months:0 weeks:0 days:0 hours:0 minutes:-10 seconds:0];
}

- (IBAction)onSwitchValueChanged:(id)sender {
    self.alarm.state = @(self.sevenSwitch.on);
}

- (void)setCellStatusOn:(BOOL)isOn {
    if (isOn) {
        self.mondayLabel.alpha = 1.0f;
        self.timeLabel.alpha = 1.0f;
        self.plusButton.alpha = 1.0f;
        self.minusButton.alpha = 1.0f;
        self.nextImageView.alpha = 1.0f;
        [self.sevenSwitch setOn:YES animated:NO];
    }
    else {
        self.mondayLabel.alpha = .36f;
        self.timeLabel.alpha = .36f;
        self.plusButton.alpha = .36f;
        self.minusButton.alpha = .36f;
        self.nextImageView.alpha = .36f;
        [self.sevenSwitch setOn:NO animated:NO];
    }
}

- (void)setAlarm:(EWAlarm *)alarm {
    _alarm = alarm;
    
    @weakify(self);
    [RACObserve(alarm, time) subscribeNext:^(NSDate *date) {
        @strongify(self);
        self.mondayLabel.text = alarm.time.mt_stringFromDateWithFullWeekdayTitle;
        self.timeLabel.text = [alarm.time mt_stringFromDateWithFormat:@"hh:mm a" localized:YES];
    }];
    
    [RACObserve(alarm, state) subscribeNext:^(NSNumber *state) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setCellStatusOn:state.boolValue];
        });
    }];
}
@end
