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

- (void)testSleep{
    //sleep
    [[EWWakeUpManager sharedInstance] sleep];
    NSDate *alarmTime = [EWWakeUpManager sharedInstance].currentActivity.time;
    NSLog(@"Current alarm time is: %@", alarmTime);
    XCTAssert([EWSession sharedSession].isSleeping, @"Sleep status not detacted");
}

- (void)testAlarmTimeUp{
    //waking up: test for 30s and expect local notification is fired
        [[EWWakeUpManager sharedInstance] handleAlarmTimerEvent:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    //expected states
    XCTAssert([EWSession sharedSession].isWakingUp, @"Failed to wake up");
    //wait for notification
    [[NSNotificationCenter defaultCenter] addObserverForName:kWakeTimeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        XCTAssert([EWAVManager sharedManager].player.isPlaying, @"AVManager is not playing");
        //wait for sound playing for 30s
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [expectation fulfill];
        });
    }];
    
    
    //async test
    [self waitForExpectationsWithTimeout:50.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testWake{
    //wake up
    NSDate *alarmTime = [EWWakeUpManager sharedInstance].currentActivity.time;
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
