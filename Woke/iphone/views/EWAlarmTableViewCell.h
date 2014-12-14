//
//  EWAlertTableViewCell.h
//  Woke
//
//  Created by Zitao Xiong on 12/7/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EWAlarm, SevenSwitch;
@interface EWAlarmTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *plusButton;
@property (weak, nonatomic) IBOutlet UIButton *minusButton;
@property (weak, nonatomic) IBOutlet UILabel *mondayLabel;
@property (nonatomic, strong) EWAlarm *alarm;
@property (weak, nonatomic) IBOutlet SevenSwitch *sevenSwitch;
@property (nonatomic, assign, getter=isNextAlarm) BOOL nextAlarm;

- (IBAction)onPlusButton:(id)sender;
- (IBAction)onMinusButton:(id)sender;
- (IBAction)onSwitchValueChanged:(id)sender;
@end
