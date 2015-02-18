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

NSString *kShowWakeUpChildVCNotification = @"kShowWakeUpChildVCNotification";
NSString *kHideWakeUpChildVCNotification = @"kHideWakeUpChildVCNotification";

FBTweakAction(@"Sleeping VC", @"UI", @"Show Wake Up VC", ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowWakeUpChildVCNotification object:nil];
});

FBTweakAction(@"Sleeping VC", @"UI", @"Hide Wake Up VC", ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideWakeUpChildVCNotification object:nil];
});

FBTweakAction(@"Sleeping VC", @"Action", @"Add People to Wake up[With Delay 5]", ^{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //DDLogInfo(@"Add Woke Voice");
        [[EWMediaManager sharedInstance] getWokeVoice];
    });
});

FBTweakAction(@"Sleeping VC", @"Action", @"Add People to Wake up", ^{
    //DDLogInfo(@"Add Woke Voice");
    [[EWMediaManager sharedInstance] getWokeVoice];
});
@interface EWSleepingViewController ()<EWBaseViewNavigationBarButtonsDelegate>
@property (nonatomic, strong) EWTimeChildViewController *timeChildViewController;
@property (nonatomic, strong) EWPeopleArrayChildViewController *peopleArrayChildViewController;
@property (nonatomic, strong) EWAlarm *nextAlarm;
@property (nonatomic, strong) EWWakeUpChildViewController *wakeUpChildViewController;
@property (nonatomic, strong) RACDisposable *timerDisposable;
@end

@implementation EWSleepingViewController
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    @weakify(self);
    self.timeChildViewController.topLabelLine1.text = [NSString stringWithFormat:@"It is now %@.", [[NSDate date] mt_stringFromDateWithFormat:@"hh:mma" localized:YES]];
    self.timerDisposable = [[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSDate *date) {
        @strongify(self);
        self.timeChildViewController.topLabelLine1.text = [NSString stringWithFormat:@"It is now %@.", [date mt_stringFromDateWithFormat:@"hh:mma" localized:YES]];
    }];
    
    RAC(self, timeChildViewController.date) = [RACObserve(self, nextAlarm.time) distinctUntilChanged];
    
    
    self.wakeUpChildViewController.view.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showWakeUpVC) name:kShowWakeUpChildVCNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideWakeUpVC) name:kHideWakeUpChildVCNotification object:nil];
}

- (void)showWakeUpVC {
    self.wakeUpChildViewController.view.hidden = NO;
    self.wakeUpChildViewController.active = YES;
    self.timeChildViewController.view.hidden = YES;
    self.peopleArrayChildViewController.view.hidden = YES;
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
        self.peopleArrayChildViewController.people = [[EWPerson myUnreadMedias] bk_map:^id(EWMedia *obj) {
            return obj.author;
        }];
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
        [[EWWakeUpManager sharedInstance] unsleep];
    }
    else if ([segue.destinationViewController isKindOfClass:[EWPostWakeUpViewController class]]) {
        //wake up
        [[EWWakeUpManager sharedInstance] wake:nil];
    }
    
    DDLogVerbose(@"Segue on SleepView: %@", segue.identifier);
}


@end
