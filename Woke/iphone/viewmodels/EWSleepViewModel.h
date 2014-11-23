//
//  EWSleepViewModel.h
//  Woke
//
//  Created by Zitao Xiong on 23/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWSleepViewModel : NSObject
@property (nonatomic, strong) NSString *time1;
@property (nonatomic, strong) NSString *time2;
@property (nonatomic, strong) NSString *time3;
@property (nonatomic, strong) NSString *time4;
@property (nonatomic, strong) NSString *ampm;
@property (nonatomic, strong) NSString *dateString;
@property (nonatomic, strong) NSString *timeLeft;
@property (nonatomic, strong) NSString *wakeupText;
@end
