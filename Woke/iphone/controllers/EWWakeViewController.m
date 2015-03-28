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
#import "AFNetworkReachabilityManager.h"

@interface EWWakeViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (nonatomic, strong) EWPerson *nextWakee;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *wantsToWakeUpAtLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *wakeButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (nonatomic, strong) RACDisposable *reachabilityDisposable;

@end

@implementation EWWakeViewController

- (void)dealloc {
    [self.reachabilityDisposable dispose];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    [[EWPersonManager shared] nextWakeeWithCompletion:^(EWPerson *person) {
        if (person) {
            [EWUIUtil dismissHUD];
            self.nextWakee = person;
        } else {
            [EWUIUtil showFailureHUBWithString:@"Failed to fetch wakee"];
            //TODO: [Zitao] handle Offline senario
        }
        
    }];
    
    if ([EWPersonManager shared].wakeeList.count == 0 && !_nextWakee) {
        [EWUIUtil showWatingHUB];
    }
    
    @weakify(self);
    self.reachabilityDisposable = [RACObserve([AFNetworkReachabilityManager sharedManager], reachable) subscribeNext:^(NSNumber *reachable) {
        @strongify(self);
        if (reachable.boolValue) {
            [self updateViewWithCurrentWakee];
        }
        else {
            [self updateViewForOffline];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.profileImageView applyHexagonSoftMask];
}

- (IBAction)onNextButton:(id)sender {
    [[EWPersonManager shared] nextWakeeWithCompletion:^(EWPerson *person) {
        self.nextWakee = person;
        NSString *title = [NSString stringWithFormat:@"Wake %@", person.genderSubjectiveCaseString];
        [self.wakeButton setTitle:title forState:UIControlStateNormal];
    }];
}

- (IBAction)onWakeHerButton:(id)sender {
}

- (void)setNextWakee:(EWPerson *)nextWakee {
    _nextWakee = nextWakee;
    
    [self updateViewWithCurrentWakee];
}

- (void)updateViewForOffline {
    self.profileImageView.image = [ImagesCatalog wokePlaceholderUserProfileImageOther];
    self.nameLabel.alpha = 0.5;
    self.wantsToWakeUpAtLabel.alpha = 0.5;
    self.statusLabel.alpha = 0.5;
    
    self.wakeButton.enabled = NO;
    self.nextButton.enabled = NO;
}

- (void)updateViewWithCurrentWakee {
    EWPerson *nextWakee = self.nextWakee;
    self.profileImageView.image = nextWakee.profilePic;
    self.nameLabel.alpha = 1.0f;
    self.nameLabel.text = nextWakee.name;
    NSDate *nextTime = [[EWAlarmManager sharedInstance] nextAlarmTimeForPerson:nextWakee];
    self.wantsToWakeUpAtLabel.text = [NSString stringWithFormat:@"wants to wake up at %@", [nextTime mt_stringFromDateWithHourAndMinuteFormat:MTDateHourFormat12Hour]];
    self.wantsToWakeUpAtLabel.alpha = 1.0f;
    self.statusLabel.text = [[EWAlarmManager sharedInstance] nextStatementForPerson:nextWakee];
    self.statusLabel.alpha = 1.0f;

    self.wakeButton.enabled = YES;
    self.nextButton.enabled = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.destinationViewController isKindOfClass:[EWProfileViewController class]]) {
        EWProfileViewController *vc = segue.destinationViewController;
        vc.person = _nextWakee;
    } else if ([segue.identifier isEqualToString:MainStoryboardIDs.segues.wakeToRecorder]){
        EWRecordingViewController *vc = segue.destinationViewController;
        vc.person = _nextWakee;
    }
}
@end
