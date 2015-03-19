//
//  EWSleepingViewController.m
//  Woke
//
//  Created by Zitao Xiong on 1/11/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWSleepingViewController.h"
#import "EWTimeChildViewController.h"
#import "EWAlarm.h"
#import "EWPerson.h"
#import "EWPerson+Woke.h"
#import "EWPeopleArrayChildViewController.h"
#import "NSArray+BlocksKit.h"
#import "EWMedia.h"
#import "FBTweak.h"
#import "FBTweakInline.h"
#import "EWWakeUpChildViewController.h"
#import "EWMediaManager.h"
#import "UIViewController+Blur.h"
#import "EWPostWakeUpViewController.h"
#import "EWWakeUpManager.h"
#import "EWSleepViewController.h"
#import "EWUIUtil.h"
#import "FBKVOController.h"
#import "EWActivity.h"
#import "FBShimmeringView.h"


FBTweakAction(@"Sleeping VC", @"UI", @"Show Wake Up VC", ^{
    //[[NSNotificationCenter defaultCenter] postNotificationName:kShowWakeUpChildVCNotification object:nil];
    [EWSession sharedSession].wakeupStatus = EWWakeUpStatusWakingUp;
});

FBTweakAction(@"Sleeping VC", @"UI", @"Hide Wake Up VC", ^{
    //[[NSNotificationCenter defaultCenter] postNotificationName:kHideWakeUpChildVCNotification object:nil];
    [EWSession sharedSession].wakeupStatus = EWWakeUpStatusSleeping;
});

FBTweakAction(@"Sleeping VC", @"Action", @"Add People to Wake up[With Delay 5]", ^{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //DDLogInfo(@"Add Woke Voice");
        [[EWMediaManager sharedInstance] getWokeVoiceWithCompletion:^(EWMedia *media, NSError *error) {
            DDLogInfo(@"Voice added");
        }];
    });
});

FBTweakAction(@"Sleeping VC", @"Action", @"Add new voice to Wake up", ^{
    //DDLogInfo(@"Add Woke Voice");
	[[EWMediaManager sharedInstance] getWokeVoiceWithCompletion:^(EWMedia *media, NSError *error) {
        DDLogInfo(@"Voice added");
    }];
});




@interface EWSleepingViewController ()<EWBaseViewNavigationBarButtonsDelegate>{
    id wakeEnabledObserver;
}
@property (nonatomic, strong) EWTimeChildViewController *timeChildViewController;
@property (nonatomic, strong) EWPeopleArrayChildViewController *peopleArrayChildViewController;
@property (nonatomic, strong) EWAlarm *nextAlarm;
@property (nonatomic, strong) EWWakeUpChildViewController *wakeUpChildViewController;
@property (nonatomic, strong) RACDisposable *timerDisposable;
@property (weak, nonatomic) IBOutlet FBShimmeringView *shimmeringView;
@property (nonatomic, strong) UILabel *slideLabel;
@property (nonatomic, assign) BOOL shouldComplete;
@end

@implementation EWSleepingViewController
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:wakeEnabledObserver];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //add unwind action
    [self.navigationItem.leftBarButtonItem setAction:@selector(close:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNewMediaNotification) name:kNewMediaNotification object:nil];
    
    self.nextAlarm = [EWPerson myCurrentAlarm];
    self.peopleArrayChildViewController.people = [[EWPerson myUnreadMedias] bk_map:^id(EWMedia *obj) {
        return obj.author;
    }];
	
	
	if ([EWSession sharedSession].wakeupStatus == EWWakeUpStatusWakingUp)
		[self showWakeUpVC];else [self hideWakeUpVC];
	[self.KVOController observe:[EWSession sharedSession] keyPath:@"wakeupStatus" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
		if ([EWSession sharedSession].wakeupStatus == EWWakeUpStatusWakingUp) {
            [[EWWakeUpManager sharedInstance] playNextVoice];
			[self showWakeUpVC];
		}else{
			[self hideWakeUpVC];
		}
	}];
	
    @weakify(self);
    //time labels
    self.timeChildViewController.topLabelLine1.text = [NSString stringWithFormat:@"It is now %@.", [[NSDate date] mt_stringFromDateWithFormat:@"hh:mma" localized:YES]];
    self.timerDisposable = [[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSDate *date) {
        @strongify(self);
        self.timeChildViewController.topLabelLine1.text = [NSString stringWithFormat:@"It is now %@.", [date mt_stringFromDateWithFormat:@"hh:mma" localized:YES]];
    }];
    //wake enabled change
    wakeEnabledObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kEWWakeEnabled object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.slideLabel.text = @"Slide to Wake Up";
    }];
    
    RAC(self, timeChildViewController.date) = [RACObserve(self, nextAlarm.time) distinctUntilChanged];
	
    self.slideLabel = [[UILabel alloc] initWithFrame:self.shimmeringView.bounds];
    self.slideLabel.font = [UIFont fontWithName:@"Lato-Light" size:24];
    self.slideLabel.textColor = [UIColor whiteColor];
    self.slideLabel.text = @"Slide to Cancel";
    self.slideLabel.textAlignment = NSTextAlignmentCenter;
    
    self.shimmeringView.contentView = self.slideLabel;
    self.shimmeringView.shimmering = YES;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGesture:)];
    [self.shimmeringView addGestureRecognizer:panGesture];
}

- (void)onPanGesture:(UIPanGestureRecognizer *)sender {
    //TODO: add interactive transition: http://nsscreencast.com/episodes/88-interactive-view-controller-transitions
    CGPoint translation = [sender translationInView:self.shimmeringView.superview];
    
    UIGestureRecognizerState state = sender.state;
    switch (state) {
        case UIGestureRecognizerStateBegan:
            break;
            
        case UIGestureRecognizerStateChanged: {
            const CGFloat DragAmount = 200;
            const CGFloat Threshold = 0.5;
            CGFloat percent = translation.x / DragAmount;
            percent = fmaxf(percent, 0.0);
            percent = fminf(percent, 1.0);
//            [self updateInteractiveTransition:percent];
            
            _shouldComplete = percent >= Threshold;
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (sender.state == UIGestureRecognizerStateCancelled || !_shouldComplete) {
//                [self cancelInteractiveTransition];
            } else {
                [self finishInteractiveTransition];
            }
            break;
        }
            
            
        default:
            break;
    }
}

- (void)finishInteractiveTransition {
    
    if ([EWWakeUpManager sharedInstance].canWakeUp) {
        [self performSegueWithIdentifier:MainStoryboardIDs.segues.sleepingToPostWakeup sender:self];
    } else {
        [self close:nil];
    }
}

- (void)showWakeUpVC {
    self.wakeUpChildViewController.view.hidden = NO;
    self.wakeUpChildViewController.active = YES;
    self.timeChildViewController.view.hidden = YES;
	self.peopleArrayChildViewController.view.hidden = YES;
	self.navigationItem.leftBarButtonItem = nil;
}

- (void)hideWakeUpVC {
    self.wakeUpChildViewController.view.hidden = YES;
    self.wakeUpChildViewController.active = NO;
    self.timeChildViewController.view.hidden = NO;
    self.peopleArrayChildViewController.view.hidden = NO;
}

- (void)onNewMediaNotification {
    //Delay update people
    //TODO: Zitao fixed new media handling, and chenged "getWokeVoice" to background, check if the unread medias is correct.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.peopleArrayChildViewController.people = [[EWPerson myUnreadMedias] valueForKey:EWMediaRelationships.author];
    });
}

#pragma mark - UI
- (IBAction)close:(id)sender{
    if (self.presentingViewController){
        [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
        [[EWWakeUpManager sharedInstance] unsleep];
    }
    else if(self.navigationController){
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.destinationViewController isKindOfClass:[EWSleepViewController class]]) {
        //back to mormal
        DDLogInfo(@"===> Unsleep");
        [[EWWakeUpManager sharedInstance] unsleep];
    }
    //the logic of wake up is seperated, change the logic to
//    else if ([segue.destinationViewController isKindOfClass:[EWPostWakeUpViewController class]]) {
//        //wake up
//        NSAssert(NO, @"The slide to wake up gesture should handle the view transition, instead of segue");
//        [[EWWakeUpManager sharedInstance] startToWakeUp];
//    }
    
    DDLogVerbose(@"Segue on SleepView: %@", segue.identifier);
}


- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    if ([identifier isEqualToString:@"toPostWakeUpView"]) {
        //it's related to to time, do not use delegate's method
		EWActivity *activity = [EWPerson myCurrentAlarmActivity];
        BOOL shouldWakeUp = [activity.time timeIntervalSinceDate:[NSDate date]] < kMaxEalyWakeInterval;
        if (!shouldWakeUp) {
            [EWUIUtil showWarningHUBWithString:@"Too early!"];
        }
        return shouldWakeUp;
    }
    return YES;
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender{
	if ([EWWakeUpManager shared].canSnooze) {
		return YES;
	}
	
	[EWUIUtil showWarningHUBWithString:@"You can't to back to sleep"];
	return NO;
}

//- (IBAction)onSlideToWakup:(id)sender {
//    EWActivity *activity = [EWPerson myCurrentAlarmActivity];
//    BOOL shouldWakeUp = [activity.time timeIntervalSinceDate:[NSDate date]] < kMaxEalyWakeInterval;
//    if (shouldWakeUp || [EWWakeUpManager sharedInstance].forceWakeUp) {
//        [self performSegueWithIdentifier:MainStoryboardIDs.segues.sleepingToPostWakeup sender:self];
//    }
//    else {
//        [EWUIUtil showWarningHUBWithString:@"Too early!"];
//    }
//}

#pragma mark - Unwind
- (IBAction)unwindToSleepingViewController:(UIStoryboardSegue *)segue {
    
}
@end
