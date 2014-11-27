//
//  alarmTest.m
//  Woke
//
//  Created by Lee on 11/23/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EWAlarmManager.h"
#import "EWUserManager.h"
#import "EWAccountManager.h"
#import "EWAlarmScheduleViewController.h"
#import "UIWindow+Extensions.h"

@interface AlarmTest : XCTestCase

@end

@implementation AlarmTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    XCTestExpectation *expectation =
    [self expectationWithDescription:@"High Expectations"];
    
    //schedule alarm

    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];

}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        NSLog(@"text");
    }];
}

@end
