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
        self.dateString = @"-";
        self.wakeupText = @"";
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
        self.date = date;
    }];
    
    [RACObserve(alarm, statement) subscribeNext:^(NSString *statement) {
        @strongify(self);
        self.wakeupText = statement;
    }];
}
@end
