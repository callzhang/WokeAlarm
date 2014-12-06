//
//  WokeTests.m
//  WokeTests
//
//  Created by Zitao Xiong on 11/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//


/**
 *  Test the next wakee
 */


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EWPersonManager.h"

@interface WokeTests : XCTestCase

@end

@implementation WokeTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNextWakee {
    // Test next wakee
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    
    [[EWPersonManager sharedInstance] nextWakeeWithCompletion:^(EWPerson *person) {
        if (person) {
            NSLog(@"Next wakee: %@", person.name);
            [expectation fulfill];
        }else{
            XCTAssert(NO, @"No wakee returned");
        }
    }];
    
    
    
    [self waitForExpectationsWithTimeout:60.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        [[EWPersonManager sharedInstance] nextWakeeWithCompletion:^(EWPerson *person) {
            NSLog(@"Next wakee: %@", person.name);
        }];
    }];
}

@end
