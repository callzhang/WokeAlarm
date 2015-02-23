//
//  EWTimeChildViewController.m
//  Woke
//
//  Created by Zitao Xiong on 1/11/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWTimeChildViewController.h"
#import "EWWakeUpManager.h"

@interface EWTimeChildViewController ()
@property (weak, nonatomic) IBOutlet UILabel *labelTime1;
@property (weak, nonatomic) IBOutlet UILabel *labelTime2;
@property (weak, nonatomic) IBOutlet UILabel *labelTime3;
@property (weak, nonatomic) IBOutlet UILabel *labelTime4;
@property (weak, nonatomic) IBOutlet UILabel *labelAmpm;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *firstLetterWidthConstraint;
@end

@implementation EWTimeChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kAlarmTimerDidFireNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.topLabelLine2.text = @"Current Alarm";
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kWakeupSuccess object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.topLabelLine2.text = @"Next Alarm";
    }];
    
    @weakify(self);
    [RACObserve(self, date) subscribeNext:^(NSDate *date) {
        @strongify(self);
        NSString *hour = [date mt_stringFromDateWithFormat:@"h" localized:NO];
        NSString *minutes = [date mt_stringFromDateWithFormat:@"mm" localized:NO];
        if (hour.length == 1) {
            self.labelTime1.text = @"";
            self.firstLetterWidthConstraint.constant = 0;
            self.labelTime2.text = hour;
        }
        else if (hour.length == 2) {
            self.labelTime1.text = @"1";
            if (self.type == EWTimeChildViewControllerTypeNormal) {
                self.firstLetterWidthConstraint.constant = 50;
            }
            else if (self.type == EWTimeChildViewControllerTypeSmall) {
                self.firstLetterWidthConstraint.constant = 38;
            }
            self.labelTime2.text = [hour substringWithRange:NSMakeRange(1, 1)];
        }
        
        self.labelTime3.text = [minutes substringWithRange:NSMakeRange(0, 1)];
        self.labelTime4.text = [minutes substringWithRange:NSMakeRange(1, 1)];
    }];
}

@end
