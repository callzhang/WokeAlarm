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
#import "EWAVManager.h"
#import "EWPerson+Woke.h"
#import "EWActivityManager.h"
#import "EWDefines.h"

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
    EWActivity *activity = [EWPerson myCurrentAlarmActivity];
    NSLog(@"Current activit: %@", activity);
    EWAlarm *alarm = [EWPerson myCurrentAlarm];
    NSLog(@"Current alarm: %@", alarm);
    XCTAssertEqual(activity.time, alarm.time.nextOccurTime);
}

- (void)testSleep{
    //sleep
    [[EWWakeUpManager sharedInstance] sleep:nil];
    NSDate *alarmTime = [EWPerson myCurrentAlarm].time;
    NSLog(@"Current alarm time is: %@", alarmTime);
    XCTAssert([EWSession sharedSession].wakeupStatus == EWWakeUpStatusSleeping, @"Sleep status not detacted");
}

- (void)testAlarmTimeUp{
    //waking up: test for 30s and expect local notification is fired
    [[EWWakeUpManager sharedInstance] startToWakeUp];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    //expected states
	if ([EWSession sharedSession].wakeupStatus != EWWakeUpStatusWakingUp) {
		NSLog(@"WakeUp test cancelled: status is not EWWakeUpStatusWakingUp");
		[expectation fulfill];
	}
    //wait for notification
    [[NSNotificationCenter defaultCenter] addObserverForName:kWakeStartNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            XCTAssert([EWSession sharedSession].wakeupStatus == EWWakeUpStatusWakingUp, @"wake up status not expected");
            [expectation fulfill];
            //TODO: [Zitao] need the base view controller respose to the "kWakeStartNotification" notification and present wake up view
            //wait for sound playing for 30s
            if ([EWAVManager sharedManager].player.isPlaying) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //
                });
            }
            
        });
        
    }];
    
    
    //async test
    [self waitForExpectationsWithTimeout:60.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testWake{
    //wake up
    NSDate *alarmTime = [EWPerson myCurrentAlarmActivity].time;
	NSLog(@"Next alarm time is: %@", alarmTime);
    [[EWWakeUpManager sharedInstance] wake:nil];
    NSDate *nextAlarmTime = [EWPerson myCurrentAlarmActivity].time;
    NSLog(@"Next activity time is: %@", nextAlarmTime);
    XCTAssert(abs([alarmTime timeIntervalSinceDate:nextAlarmTime])<1);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
