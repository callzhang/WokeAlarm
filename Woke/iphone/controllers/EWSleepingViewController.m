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

@interface EWSleepingViewController ()
@property (nonatomic, strong) EWTimeChildViewController *timeChildViewController;
@property (nonatomic, strong) EWPeopleArrayChildViewController *peopleArrayChildViewController;
@property (nonatomic, strong) EWAlarm *nextAlarm;
@property (nonatomic, strong) RACDisposable *timerDisposable;
@end

@implementation EWSleepingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.nextAlarm = [EWPerson myCurrentAlarm];
    self.peopleArrayChildViewController.people = [[EWPerson myUnreadMedias] bk_map:^id(EWMedia *obj) {
        return obj.author;
    }];
    
    @weakify(self);
    self.timerDisposable = [[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSDate *date) {
       @strongify(self);
        self.timeChildViewController.topLabelLine1.text = [NSString stringWithFormat:@"It is now %@.", [date mt_stringFromDateWithFormat:@"hh:mma" localized:YES]];
    }];
    
    RAC(self, timeChildViewController.date) = [RACObserve(self, nextAlarm.time) distinctUntilChanged];
}
@end
