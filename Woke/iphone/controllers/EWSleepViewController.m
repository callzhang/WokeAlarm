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
#import "EWAccountManager.h"
#import "EWSleepingViewController.h"
#import "UIViewController+Blur.h"
#import "EWUIUtil.h"
#import "JGProgressHUD.h"
#import "FBTweak.h"
#import "FBTweakInline.h"
#import "NSTimer+BlocksKit.h"
#import "FBKVOController.h"

@interface EWSleepViewController (){
    EWAlarm *currentAlarm;
}

@property (weak, nonatomic) IBOutlet UILabel *labelDateString;
@property (weak, nonatomic) IBOutlet UILabel *labelTimeLeft;
@property (weak, nonatomic) IBOutlet UILabel *labelWakeupText;
@property (nonatomic, strong) EWTimeChildViewController *timeChildViewController;
@end

@implementation EWSleepViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sleepViewModel = [[EWSleepViewModel alloc] init];
    
    [self setViewModelAlarm];
    
    //remove background color set in interface builder[used for layouting].
    self.view.backgroundColor = [UIColor clearColor];
    
    self.timeChildViewController.topLabelLine1.text = @"";
    self.timeChildViewController.topLabelLine2.text = @"Next Alarm";
    
    [NSTimer bk_scheduledTimerWithTimeInterval:1 block:^(NSTimer *timer) {
        //self.timeChildViewController.topLabelLine1.text = [NSDate date].date2String;
        self.labelDateString.text = currentAlarm.time.nextOccurTime.date2dayString;
        self.labelTimeLeft.text = currentAlarm.time.nextOccurTime.timeLeft;
    } repeats:YES];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:kUserSyncStarted object:nil queue:nil usingBlock:^(NSNotification *note) {
		JGProgressHUD *hud = [EWUIUtil showWatingHUB];
        hud.textLabel.text = @"Syncing data";
	}];
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserSyncCompleted object:nil queue:nil usingBlock:^(NSNotification *note) {
		[EWUIUtil dismissHUD];
		[self setViewModelAlarm];
	}];
    [[NSNotificationCenter defaultCenter] addObserverForName:kAlarmTimeChanged object:nil queue:nil usingBlock:^(NSNotification *note) {
        DDLogInfo(@"Sleep view feels there is a change to alarm time, updating view.");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setViewModelAlarm];
        });
    }];
    [self.KVOController observe:[EWWakeUpManager shared] keyPath:@"wakeupStatus" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        [self setViewModelAlarm];
    }];
    
    if ([EWSession sharedSession].isSyncingUser == YES) {
        JGProgressHUD *hud = [EWUIUtil showWatingHUB];
        hud.textLabel.text = @"Syncing data";
    }
    [self bindViewModel];
}

- (void)setViewModelAlarm {
    currentAlarm = [EWPerson myCurrentAlarm];
    self.sleepViewModel.alarm = currentAlarm;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
#ifdef DEBUG
    //add testing button
    UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc] initWithImage:[ImagesCatalog moreButton] style:UIBarButtonItemStyleDone target:self action:@selector(more:)];
    self.navigationItem.rightBarButtonItem = rightBtn;
#endif
}

- (void)bindViewModel {
    RAC(self.labelDateString, text)= [RACObserve(self.sleepViewModel, dateString) distinctUntilChanged];
    RAC(self.labelWakeupText, text)= [RACObserve(self.sleepViewModel, wakeupText) distinctUntilChanged];
    RAC(self, timeChildViewController.date) = [RACObserve(self.sleepViewModel, date) distinctUntilChanged];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:@"toSetStatusController"]) {
        EWSetStatusViewController *viewController = [[segue.destinationViewController viewControllers] firstObject];
        viewController.person = [EWPerson me];
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

- (IBAction)more:(id)sender{
    [EWUtil showTweakPanel];
}
@end
