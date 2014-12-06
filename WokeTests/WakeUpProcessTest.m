//
//  WakeUpProcessTest.m
//  Woke
//
//  Created by Lee on 12/5/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EWWakeUpManager.h"
#import "EWActivity.h"
#import "EWAlarm.h"
#import "MagicalRecord.h"
#import "CoreData+MagicalRecord.h"
#import "EWAlarmManager.h"
#import "EWPerson.h"
#import "NSDate+Extend.h"

@interface WakeUpProcessTest : XCTestCase

@end

@implementation WakeUpProcessTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCurrentAlarm{
    EWActivity *activity = [EWWakeUpManager sharedInstance].currentActivity;
    NSLog(@"Current activit: %@", activity);
    EWAlarm *alarm = [EWWakeUpManager sharedInstance].alarm;
    NSLog(@"Current alarm: %@", alarm);
    XCTAssertEqual(activity.time, alarm.time.nextOccurTime);
}

- (void)testSleepAndWake{
    [[EWWakeUpManager sharedInstance] sleep];
    NSDate *alarmTime = [EWWakeUpManager sharedInstance].currentActivity.time;
    NSLog(@"Current alarm time is: %@", alarmTime);
    //push the sleep view
    //wake up
    [[EWWakeUpManager sharedInstance] wake];
    NSDate *nextAlarmTime = [EWWakeUpManager sharedInstance].currentActivity.time;
    NSLog(@"Next alarm time is: %@", nextAlarmTime);
    XCTAssert([alarmTime isEqualToDate:nextAlarmTime]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
