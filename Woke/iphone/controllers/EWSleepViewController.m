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
#import "EWUtil.h"

@interface EWSleepViewController ()
@property (weak, nonatomic) IBOutlet UILabel *labelDateString;
@property (weak, nonatomic) IBOutlet UILabel *labelTimeLeft;
@property (weak, nonatomic) IBOutlet UILabel *labelWakeupText;
@property (nonatomic, strong) EWTimeChildViewController *timeChildViewController;
@property (nonatomic, strong) NSTimer *displayTimer;
@property (nonatomic, strong) id userSyncStartedObserver;
@property (nonatomic, strong) id userSyncCompletedObserver;
@property (nonatomic, strong) id alarmTimeChangeObserver;
@property (nonatomic, strong) id wokeObserver;
@end

@implementation EWSleepViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.userSyncCompletedObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.userSyncStartedObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.alarmTimeChangeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.wokeObserver];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sleepViewModel = [[EWSleepViewModel alloc] init];
    
    self.sleepViewModel.alarm = [EWPerson myCurrentAlarm];
    
    //remove background color set in interface builder[used for layouting].
    self.view.backgroundColor = [UIColor clearColor];
    
    self.timeChildViewController.topLabelLine1.text = @"";
    self.timeChildViewController.topLabelLine2.text = @"Next Alarm";
	
    @weakify(self);
	[self.displayTimer invalidate];
    self.displayTimer = [NSTimer bk_scheduledTimerWithTimeInterval:1 block:^(NSTimer *timer) {
        @strongify(self);
        self.labelDateString.text = self.sleepViewModel.alarm.time.nextOccurTime.date2dayString;
        self.labelTimeLeft.text = self.sleepViewModel.alarm.time.nextOccurTime.timeLeft;
    } repeats:YES];
	
	self.userSyncStartedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kUserSyncStarted object:nil queue:nil usingBlock:^(NSNotification *note) {
		JGProgressHUD *hud = [EWUIUtil showWatingHUB];
        hud.textLabel.text = @"Syncing data";
	}];
    
    self.userSyncCompletedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kUserSyncCompleted object:nil queue:nil usingBlock:^(NSNotification *note) {
		[EWUIUtil dismissHUD];
        self.sleepViewModel.alarm = [EWPerson myCurrentAlarm];
	}];
    
    self.wokeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kWokeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [NSTimer bk_scheduledTimerWithTimeInterval:kMaxWakeTime+1 block:^(NSTimer *timer) {
            self.sleepViewModel.alarm = [EWPerson myCurrentAlarm];
        } repeats:NO];
    }];
    
    self.alarmTimeChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAlarmTimeChanged object:nil queue:nil usingBlock:^(NSNotification *note) {
        DDLogInfo(@"Sleep view feels there is a change to alarm time, updating view.");
        self.sleepViewModel.alarm = [EWPerson myCurrentAlarm];
    }];
    
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
#ifdef DEBUG
    //add testing button
    UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc] initWithImage:[ImagesCatalog moreButton] style:UIBarButtonItemStyleDone target:self action:@selector(more:)];
    self.parentViewController.navigationItem.rightBarButtonItem = rightBtn;
#endif
}

- (void)bindViewModel {
    RAC(self.labelDateString, text)= [RACObserve(self.sleepViewModel, dateString) distinctUntilChanged];
    RAC(self.labelWakeupText, text)= [RACObserve(self.sleepViewModel, wakeupText) distinctUntilChanged];
    RAC(self, timeChildViewController.date) = [RACObserve(self.sleepViewModel, date) distinctUntilChanged];
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

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
	if ([identifier isEqualToString:@"toSleepingView"]){
		if (![EWWakeUpManager sharedInstance].shouldSleep) {
			[EWUIUtil showWarningHUBWithString:@"Too early"];
			return NO;
		}
	}
	return YES;
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
    [EWUtil showTweakPanel];
}
@end
