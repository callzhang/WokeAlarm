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

@interface EWSleepViewController ()

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
	
	[[NSNotificationCenter defaultCenter] addObserverForName:kUserSyncStarted object:nil queue:nil usingBlock:^(NSNotification *note) {
		[EWUIUtil showWatingHUB];
	}];
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserSyncCompleted object:nil queue:nil usingBlock:^(NSNotification *note) {
		[EWUIUtil dismissHUD];
		[self setViewModelAlarm];
	}];
    
    if ([EWSession sharedSession].isSyncingUser == YES) {
        [EWUIUtil showWatingHUB];
    }
    [self bindViewModel];
}

- (void)setViewModelAlarm {
    self.sleepViewModel.alarm = [EWPerson myCurrentAlarm];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender{
    return YES;
}
@end
