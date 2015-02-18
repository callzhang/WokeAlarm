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
#import "EWProfileViewController.h"
#import "UIViewController+Blur.h"
#import "EWRecordingViewController.h"
#import "FBKVOController.h"
#import "EWUIUtil.h"

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
        [EWUIUtil dismissHUD];
        self.nextWakee = person;
    }];
    
    if ([EWPersonManager shared].wakeeList.count == 0 && !_nextWakee) {
        [EWUIUtil showWatingHUB];
    }
    
    [self.KVOController observe:self.profileImageView keyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        DDLogInfo(@"profile pic background changed to %@", _profileImageView.backgroundColor);
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

- (void)setNextWakee:(EWPerson *)nextWakee {
    _nextWakee = nextWakee;
    
    self.profileImageView.image = nextWakee.profilePic;
    self.nameLabel.text = nextWakee.name;
    NSDate *nextTime = [[EWAlarmManager sharedInstance] nextAlarmTimeForPerson:nextWakee];
    self.wantsToWakeUpAtLabel.text = [NSString stringWithFormat:@"wants to wake up at %@", [nextTime mt_stringFromDateWithHourAndMinuteFormat:MTDateHourFormat12Hour]];
    self.statusLabel.text = [[EWAlarmManager sharedInstance] nextStatementForPerson:nextWakee];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.destinationViewController isKindOfClass:[EWProfileViewController class]]) {
        EWProfileViewController *vc = segue.destinationViewController;
        vc.person = _nextWakee;
    } else if ([segue.destinationViewController isKindOfClass:[EWRecordingViewController class]]){
        EWRecordingViewController *vc = segue.destinationViewController;
        vc.wakees = @[_nextWakee];
    }
}
@end
