//
//  EWSleepViewModel.h
//  Woke
//
//  Created by Zitao Xiong on 23/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RVMViewModel.h"
#import "EWAlarm.h"

@interface EWSleepViewModel : RVMViewModel
@property (nonatomic, strong) NSString *dateString;
@property (nonatomic, strong) NSString *timeLeft;
@property (nonatomic, strong) NSString *wakeupText;

@property (nonatomic, strong) NSDate *date;

@property (nonatomic, strong) EWAlarm *alarm;
@end
