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

@interface EWWakeViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (nonatomic, strong) EWPerson *nextWike;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *wantsToWakeUpAtLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation EWWakeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    [[EWPersonManager shared] nextWakeeWithCompletion:^(EWPerson *person) {
        self.nextWike = person;
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.profileImageView applyHexagonSoftMask];
}

- (IBAction)onNextButton:(id)sender {
    [[EWPersonManager shared] nextWakeeWithCompletion:^(EWPerson *person) {
        self.nextWike = person;
    }];
}

- (IBAction)onWakeHerButton:(id)sender {
}

- (void)setNextWike:(EWPerson *)nextWike {
    _nextWike = nextWike;
    
    self.profileImageView.image = nextWike.profilePic;
    self.nameLabel.text = nextWike.name;
    EWAlarm *nextAlarm = [[EWAlarmManager sharedInstance] nextAlarmForPerson:nextWike];
    self.wantsToWakeUpAtLabel.text = [NSString stringWithFormat:@"wants to wake up at %@", [nextAlarm.time mt_stringFromDateWithHourAndMinuteFormat:MTDateHourFormat12Hour]];
    self.statusLabel.text = nextAlarm.statement;
}
@end
