//
//  EWSleepViewModel.m
//  Woke
//
//  Created by Zitao Xiong on 23/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWSleepViewModel.h"

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

@end
