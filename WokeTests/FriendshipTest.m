//
//  FriendshipTest.m
//  Woke
//
//  Created by Lee on 2/7/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EWPersonManager.h"
#import "NSManagedObject+MagicalFinders.h"
#import "EWDefines.h"
#import "EWPerson+Woke.h"

@interface FriendshipTest : XCTestCase

@end

@implementation FriendshipTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testSendFriendshipRequest {
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    NSMutableArray *people = [EWPerson MR_findAll].mutableCopy;
    [people removeObject:[EWPerson me]];
    EWPerson *person = people[arc4random_uniform(people.count)];
    [[EWPersonManager shared] requestFriend:person completion:^(EWFriendshipStatus status, NSError *error) {
        if (status == EWFriendshipStatusSent) {
            NSLog(@"Friend request sent");
            
            //accept request
            [[EWPersonManager shared] acceptFriend:person completion:^(EWFriendshipStatus status2, NSError *error2) {
                if (status2 == EWFriendshipStatusFriended) {
                    NSLog(@"Friended");
                    XCTAssert([[EWPerson myFriends] containsObject:person], @"Person not in my friends");
                    [expectation fulfill];
                }
            }];
            
        } else {
            NSLog(@"Failed to request friend: %d", status);
            XCTAssert(NO, @"Failed");
        }
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timed out test: %s", __FUNCTION__);
        }
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
