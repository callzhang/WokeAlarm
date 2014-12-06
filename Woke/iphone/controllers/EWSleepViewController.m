//
//  EWSleepViewController.m
//  Woke
//
//  Created by Zitao Xiong on 22/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWSleepViewController.h"

@interface EWSleepViewController ()
@property (weak, nonatomic) IBOutlet UILabel *labelTime1;
@property (weak, nonatomic) IBOutlet UILabel *labelTime2;
@property (weak, nonatomic) IBOutlet UILabel *labelTime3;
@property (weak, nonatomic) IBOutlet UILabel *labelTime4;
@property (weak, nonatomic) IBOutlet UILabel *labelAmpm;
@property (weak, nonatomic) IBOutlet UILabel *labelDateString;
@property (weak, nonatomic) IBOutlet UILabel *labelTimeLeft;
@property (weak, nonatomic) IBOutlet UILabel *labelWakeupText;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *firstLetterLeadingConstraint;
@end

@implementation EWSleepViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sleepViewModel = [[EWSleepViewModel alloc] init];
    self.sleepViewModel.alarm = [EWPerson myCurrentAlarm];
   
    [self bindViewModel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //remove background color set in interface builder[used for layouting].
    self.view.backgroundColor = [UIColor clearColor];
    
    
#ifdef caoer115
    //test
    self.sleepViewModel.alarm = [EWPerson myNextAlarm];
    self.sleepViewModel.alarm.time = [NSDate mt_dateFromYear:200 month:0 day:0 hour:12 minute:50];
#endif
}

- (void)bindViewModel {
    RAC(self.labelTime1, text, @"") = [RACObserve(self.sleepViewModel, time1) distinctUntilChanged];
    RAC(self.labelTime2, text)= [RACObserve(self.sleepViewModel, time2) distinctUntilChanged];
    RAC(self.labelTime3, text)= [RACObserve(self.sleepViewModel, time3) distinctUntilChanged];
    RAC(self.labelTime4, text)= [RACObserve(self.sleepViewModel, time4) distinctUntilChanged];
    RAC(self.labelDateString, text)= [RACObserve(self.sleepViewModel, dateString) distinctUntilChanged];
    RAC(self.labelWakeupText, text)= [RACObserve(self.sleepViewModel, wakeupText) distinctUntilChanged];
    
    [RACObserve(self.sleepViewModel, time1) subscribeNext:^(NSString *value) {
        if (!value) {
            self.firstLetterLeadingConstraint.constant = -35;
        }
        else {
            self.firstLetterLeadingConstraint.constant = -5;
        }
    }];
}
@end
