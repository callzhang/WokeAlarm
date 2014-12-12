//
//  EWSleepViewController.m
//  Woke
//
//  Created by Lee on 8/6/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "EWSleepModeViewController.h"
#import "EWBackgroundingManager.h"
#import "EWAVManager.h"
#import "EWPersonManager.h"
#import "EWAlarmManager.h"
#import "EWActivityManager.h"
#import "EWActivity.h"
#import "UIViewController+Blur.h"

@interface EWSleepModeViewController (){
    NSTimer *timer;
    EWActivity *currentActivity;
}

@end

@implementation EWSleepModeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[EWBackgroundingManager sharedInstance] startBackgrounding];
	currentActivity = [EWActivityManager sharedManager].currentAlarmActivity;
	
	NSDate *cachedNextTime = [[EWAlarmManager sharedInstance] nextAlarmTimeForPerson:[EWPerson me]];
	if (![cachedNextTime isEqualToDate:currentActivity.time]) {
		[[EWAlarmManager sharedInstance] updateCachedAlarmTimes];
	}
    
    self.navigationItem.leftBarButtonItem = [self.mainNavigationController menuBarButtonItem];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //sound
    [[EWAVManager sharedManager] playSoundFromFileName:@"sleep mode.caf"];
    //time
    [self updateTimer:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [timer invalidate];
}

- (IBAction)cancel:(id)sender {
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    [[EWBackgroundingManager sharedInstance] endBackgrounding];
}

- (void)updateTimer:(NSTimer *)time{
	if (![UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
		return;
	}
    NSDate *t = [NSDate date];
    self.timeLabel.text = t.date2String;
	
	self.timeLeftLabel.text = [NSString stringWithFormat:@"%@ left", currentActivity.time.timeLeft];
    self.alarmTime.text = [NSString stringWithFormat:@"Alarm %@", currentActivity.time.date2String];
    
    if (currentActivity.time.timeIntervalSinceNow <0) {
        //task has past
		[timer invalidate];
        [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    }
    
    //timer
    timer = [NSTimer scheduledTimerWithTimeInterval:currentActivity.time.timeIntervalSinceNow/30 target:self selector:@selector(updateTimer:) userInfo:nil repeats:NO];
}
@end
