//
//  EWSleepViewModel.m
//  Woke
//
//  Created by Zitao Xiong on 23/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWSleepViewModel.h"
#import "RACEXTScope.h"
@interface EWSleepViewModel ()
@end

@implementation EWSleepViewModel
- (instancetype)init {
    self = [super init];
    if (self) {
        self.time1 = @"1";
        self.time2 = @"1";
        self.time3 = @"3";
        self.time4 = @"9";
        self.ampm = @"PM";
        self.dateString = @"Thursday, October";
        self.wakeupText = @"Wake me up plzzzzzzz!";
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.time1 = nil;
        });
    }
    return self;
}


- (void)setAlarm:(EWAlarm *)alarm {
    if (_alarm != alarm) {
        _alarm = alarm;
    }
    
    @weakify(self);
    [RACObserve(alarm, time) subscribeNext:^(NSDate *date) {
        @strongify(self);
        NSString *hour = [date mt_stringFromDateWithFormat:@"h" localized:NO];
        NSString *minutes = [date mt_stringFromDateWithFormat:@"mm" localized:NO];
        if (hour.length == 1) {
            self.time1 = nil;
            self.time2 = hour;
        }
        else if (hour.length == 2) {
            self.time1 = @"1";
            self.time2 = [hour substringWithRange:NSMakeRange(1, 1)];
        }
        
        self.time3 = [minutes substringWithRange:NSMakeRange(0, 1)];
        self.time4 = [minutes substringWithRange:NSMakeRange(1, 1)];
    }];
    
    [RACObserve(alarm, statement) subscribeNext:^(NSString *statement) {
        @strongify(self);
        self.wakeupText = statement;
    }];
}
@end
