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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPersonSyncCompleted:) name:kUserSyncCompleted object:nil];
    [self bindViewModel];
}

- (void)onPersonSyncCompleted:(NSNotification *)noti {
    [self setViewModelAlarm];
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

- (IBAction)onStatusOverlayButton:(id)sender {
    [self performSegueWithIdentifier:@"toSetStatusController" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:@"toSetStatusController"]) {
        EWSetStatusViewController *viewController = [[segue.destinationViewController viewControllers] firstObject];
        viewController.person = [EWPerson me];
    }
    else if ([segue.identifier isEqualToString:@"toSleepModeView"]){
        //[[EWWakeUpManager sharedInstance] handleSleepTimerEvent:nil];
        [[EWWakeUpManager sharedInstance] sleep:nil];
    }
}

- (IBAction)unwindToSleepViewController:(UIStoryboardSegue *)sender {
    if ([sender.identifier isEqualToString:@"unwindFromStatusViewController"]) {
        
    }
}
- (IBAction)startSleeping:(id)sender {
    [[EWWakeUpManager sharedInstance] sleep:nil];
    EWSleepingViewController *vc = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:NSStringFromClass([EWSleepingViewController class])];
    EWBaseNavigationController *nav = [(EWBaseNavigationController *)[EWBaseNavigationController alloc] initWithRootViewController:vc];
    [nav addNavigationButtons];
    [nav setNavigationBarTransparent:YES];
    [self.navigationController presentViewControllerWithBlurBackground:nav];
}
@end
