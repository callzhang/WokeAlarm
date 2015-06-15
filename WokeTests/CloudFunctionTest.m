//
//  CloudFunctionTest.m
//  Woke
//
//  Created by Lei Zhang on 12/31/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EWPerson+Woke.h"
#import "EWAccountManager.h"
#import "EWDefines.h"
#import "EWSync.h"

@interface CloudFunctionTest : XCTestCase
@property (nonatomic, strong) EWPerson *me;
@end

@implementation CloudFunctionTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.me = [EWPerson me];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/*
- (void)testSyncUser {
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    [[EWAccountManager sharedInstance] syncUserWithCompletion:^(NSError *error){
        if (!error) {
            [expectation fulfill];
        }else{
            XCTAssert(NO, @"Pass");
        }
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Failed test: %s", __FUNCTION__);
        }
    }];
}
 */

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
