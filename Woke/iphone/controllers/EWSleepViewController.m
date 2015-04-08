//
//  EWSleepViewController.m
//  Woke
//
//  Created by Zitao Xiong on 22/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWSleepViewController.h"
#import "EWSetStatusViewController.h"
#import "EWWakeUpManager.h"
#import "EWTimeChildViewController.h"
#import "EWSleepingViewController.h"
#import "UIViewController+Blur.h"
#import "EWUIUtil.h"
#import "JGProgressHUD.h"
#import "FBTweak.h"
#import "FBTweakInline.h"
#import "NSTimer+BlocksKit.h"
#import "FBKVOController.h"
#import "EWStartUpSequence.h"
#import "ATConnect.h"
#import "EWUtil.h"

@interface EWSleepViewController (){
    id userSyncStartedObserver;
    id userSyncCompletedObserver;
    id alarmTimeChangeObserver;
    id wokeObserver;
}
@property (weak, nonatomic) IBOutlet UILabel *labelDateString;
@property (weak, nonatomic) IBOutlet UILabel *labelTimeLeft;
@property (weak, nonatomic) IBOutlet UILabel *labelWakeupText;
@property (weak, nonatomic) IBOutlet UIButton *sleepButton;
@property (nonatomic, strong) EWTimeChildViewController *timeChildViewController;
@property (nonatomic, strong) NSTimer *updateSleepButtonTimer;
@end

@implementation EWSleepViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:userSyncCompletedObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:userSyncStartedObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:alarmTimeChangeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:wokeObserver];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sleepViewModel = [[EWSleepViewModel alloc] init];
    self.sleepViewModel.alarm = [EWPerson myCurrentAlarm];
    
    //remove background color set in interface builder[used for layouting].
    self.view.backgroundColor = [UIColor clearColor];
    
    self.timeChildViewController.topLabelLine1.text = @"";
    self.timeChildViewController.topLabelLine2.text = @"Next Alarm";
	
    //
    self.sleepButton.enabled = NO;
	[self.updateSleepButtonTimer invalidate];
    self.updateSleepButtonTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTextsAndButtons) userInfo:nil repeats:YES];
	
	userSyncStartedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kUserSyncStarted object:nil queue:nil usingBlock:^(NSNotification *note) {
		JGProgressHUD *hud = [EWUIUtil showWatingHUB];
        hud.textLabel.text = @"Syncing data";
	}];
    
    userSyncCompletedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kUserSyncCompleted object:nil queue:nil usingBlock:^(NSNotification *note) {
		[EWUIUtil dismissHUD];
        self.sleepViewModel.alarm = [EWPerson myCurrentAlarm];
	}];
    
    wokeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kWokeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.sleepViewModel.alarm = [EWPerson myCurrentAlarm];
    }];
    
    alarmTimeChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAlarmTimeChanged object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.sleepViewModel.alarm = [EWPerson myCurrentAlarm];
    }];
    
    @weakify(self);
    [RACObserve([EWSession sharedSession], wakeupStatus) subscribeNext:^(NSNumber *status) {
        @strongify(self);
        self.sleepViewModel.alarm = [EWPerson myCurrentAlarm];
    }];
    
    if ([EWSession sharedSession].isSyncingUser == YES) {
        JGProgressHUD *hud = [EWUIUtil showWatingHUB];
        hud.textLabel.text = @"Syncing data";
    }
    [self bindViewModel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(more:)];
    self.parentViewController.navigationItem.rightBarButtonItem = rightBtn;
}

- (void)bindViewModel {
    RAC(self.labelDateString, text)= [RACObserve(self.sleepViewModel, dateString) distinctUntilChanged];
    RAC(self.labelWakeupText, text)= [RACObserve(self.sleepViewModel, wakeupText) distinctUntilChanged];
    RAC(self, timeChildViewController.date) = [RACObserve(self.sleepViewModel, date) distinctUntilChanged];
}

- (void)updateTextsAndButtons {
    self.labelDateString.text = self.sleepViewModel.alarm.time.nextOccurTime.date2dayString;
    self.labelTimeLeft.text = self.sleepViewModel.alarm.time.nextOccurTime.timeLeft;
    
    if (self.sleepViewModel.alarm.canSleep) {
        self.sleepButton.enabled = YES;
        [self.sleepButton setTitle:@"Start Sleeping" forState:UIControlStateNormal];
    }
    else {
        self.sleepButton.enabled = NO;
        NSString *string = [NSString stringWithFormat:@"Start sleep in %@", [NSDate getStringFromTime:self.sleepViewModel.alarm.hoursAbleToSleep*3600]];
        [self.sleepButton setTitle:string forState:UIControlStateNormal];
    }
}

#pragma mark - Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:MainStoryboardIDs.segues.toStatusViewController]) {
        EWSetStatusViewController *viewController = segue.destinationViewController;
        viewController.alarm = self.sleepViewModel.alarm;
    }
    else if ([segue.destinationViewController isKindOfClass:[EWSleepingViewController class]]){
		[[EWWakeUpManager sharedInstance] sleep:nil];
    }
    else if ([segue.destinationViewController isKindOfClass:[EWSleepViewController class]]) {
        [[EWWakeUpManager sharedInstance] unsleep];
    }
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender{
	if ([EWSession sharedSession].wakeupStatus == EWWakeUpStatusWakingUp) {
		[EWUIUtil showWarningHUBWithString:@"Wake up!"];
		return NO;
	}
	return YES;
}

#pragma mark - UIAction
- (IBAction)more:(id)sender{
	[[ATConnect sharedConnection] presentMessageCenterFromViewController:self];
}
@end
