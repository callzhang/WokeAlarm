//
//  EWWakeViewController.m
//  Woke
//
//  Created by Zitao Xiong on 25/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWWakeViewController.h"
#import "EWCategories.h"
#import "EWPersonManager.h"
#import "EWAlarmManager.h"
#import "EWAlarm.h"
#import "EWPersonViewController.h"
#import "UIViewController+Blur.h"

@interface EWWakeViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (nonatomic, strong) EWPerson *nextWakee;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *wantsToWakeUpAtLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation EWWakeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    [[EWPersonManager shared] nextWakeeWithCompletion:^(EWPerson *person) {
        self.nextWakee = person;
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.profileImageView applyHexagonSoftMask];
}

- (IBAction)onNextButton:(id)sender {
    [[EWPersonManager shared] nextWakeeWithCompletion:^(EWPerson *person) {
        self.nextWakee = person;
    }];
}

- (IBAction)onWakeHerButton:(id)sender {
}

- (IBAction)profile:(id)sender {
    EWPersonViewController *vc = (EWPersonViewController *)[[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:NSStringFromClass([EWPersonViewController class])];
    //vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    vc.person = _nextWakee;
    [self presentViewControllerWithBlurBackground:vc];
}

- (void)setNextWakee:(EWPerson *)nextWakee {
    _nextWakee = nextWakee;
    
    self.profileImageView.image = nextWakee.profilePic;
    self.nameLabel.text = nextWakee.name;
    EWAlarm *nextAlarm = [[EWAlarmManager sharedInstance] currentAlarmForPerson:nextWakee];
    self.wantsToWakeUpAtLabel.text = [NSString stringWithFormat:@"wants to wake up at %@", [nextAlarm.time mt_stringFromDateWithHourAndMinuteFormat:MTDateHourFormat12Hour]];
    self.statusLabel.text = nextAlarm.statement;
}
@end
