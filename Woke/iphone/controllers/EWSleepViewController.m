//
//  EWSleepViewController.m
//  Woke
//
//  Created by Zitao Xiong on 22/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWSleepViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface EWSleepViewController ()
@property (weak, nonatomic) IBOutlet UILabel *labelTime1;
@property (weak, nonatomic) IBOutlet UILabel *labelTime2;
@property (weak, nonatomic) IBOutlet UILabel *labelTime3;
@property (weak, nonatomic) IBOutlet UILabel *labelTime4;
@property (weak, nonatomic) IBOutlet UILabel *labelAmpm;
@property (weak, nonatomic) IBOutlet UILabel *labelDateString;
@property (weak, nonatomic) IBOutlet UILabel *labelTimeLeft;
@property (weak, nonatomic) IBOutlet UILabel *labelWakeupText;
@end

@implementation EWSleepViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sleepViewModel = [[EWSleepViewModel alloc] init];
   
    [self bindViewModel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //remove background color set in interface builder[used for layouting].
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)bindViewModel {
    RAC(self.labelTime1, text, @"") = [RACObserve(self.sleepViewModel, time1) distinctUntilChanged];
    RAC(self.labelTime2, text)= [RACObserve(self.sleepViewModel, time2) distinctUntilChanged];
    RAC(self.labelTime3, text)= [RACObserve(self.sleepViewModel, time3) distinctUntilChanged];
    RAC(self.labelTime4, text)= [RACObserve(self.sleepViewModel, time4) distinctUntilChanged];
    RAC(self.labelDateString, text)= [RACObserve(self.sleepViewModel, dateString) distinctUntilChanged];
    RAC(self.labelWakeupText, text)= [RACObserve(self.sleepViewModel, wakeupText) distinctUntilChanged];
}
@end
