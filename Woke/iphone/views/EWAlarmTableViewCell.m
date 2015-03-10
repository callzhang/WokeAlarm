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
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation EWAlarmTableViewCell

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

- (void)startMinusTime {
    [self stopMinusTime];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(minusTime) userInfo:nil repeats:YES];
}

- (void)stopMinusTime {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)minusTime {
    self.alarm.time = [self.alarm.time mt_dateByAddingYears:0 months:0 weeks:0 days:0 hours:0 minutes:-10 seconds:0];
}

- (void)startPlusTime {
    [self stopPlusTime];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(plusTime) userInfo:nil repeats:YES];
}

- (void)stopPlusTime {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)plusTime {
    self.alarm.time = [self.alarm.time mt_dateByAddingYears:0 months:0 weeks:0 days:0 hours:0 minutes:10 seconds:0];
}

#pragma mark - <IBAction>
- (IBAction)onPlusButton:(id)sender {
    [self plusTime];
}

- (IBAction)onMinusButton:(id)sender {
    [self minusTime];
}

- (IBAction)touchUpInsideMinusButton:(id)sender {
    [self stopMinusTime];
    [self performScheduleNotification];
}

- (IBAction)touchUpOutsideMinusButton:(id)sender {
    [self stopMinusTime];
    [self performScheduleNotification];
}

- (IBAction)touchDownMinusButton:(id)sender {
    [self startMinusTime];
}

- (IBAction)touchDownPlusButton:(id)sender {
    [self startPlusTime];
}

- (IBAction)touchUpInsidePlusButton:(id)sender {
    [self stopPlusTime];
    [self performScheduleNotification];
}

- (IBAction)touchUpOutsideButton:(id)sender {
    [self stopPlusTime];
    [self performScheduleNotification];
}

- (IBAction)onSwitchValueChanged:(id)sender {
    self.alarm.state = @(self.sevenSwitch.on);
    if (self.sevenSwitch.on) {
        [self performScheduleNotification];
    }else{
        [self.alarm cancelLocalNotification];
    }
}

- (void)performScheduleNotification {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scheduleLocalNotification) object:nil];
    [self performSelector:@selector(scheduleLocalNotification) withObject:nil afterDelay:1];
}

- (void)scheduleNotification {
    DDLogVerbose(@"shedule notification");
    [self.alarm scheduleLocalAndPushNotification];
}

#pragma mark -

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
