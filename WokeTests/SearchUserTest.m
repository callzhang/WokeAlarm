//
//  SearchUserTest.m
//  Woke
//
//  Created by Lee on 1/25/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EWSocialManager.h"
#import "EWDefines.h"

@interface SearchUserTest : XCTestCase

@end

@implementation SearchUserTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSearchEmail {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect search result"];
    [[EWSocialManager sharedInstance] searchUserWithPhrase:@"leizhang0121@gmail.com" completion:^(NSArray *array, NSError *error){
        NSLog(@"found user: %@", array.firstObject);
        XCTAssert(array.count);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testSearchFirstName {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect search result"];
    [[EWSocialManager sharedInstance] searchUserWithPhrase:@"Lee" completion:^(NSArray *array, NSError *error){
        NSLog(@"found user: %@", array.firstObject);
        XCTAssert(array.count);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testSearchFullName {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect search result"];
    [[EWSocialManager sharedInstance] searchUserWithPhrase:@"Lee Zen" completion:^(NSArray *array, NSError *error){
        NSLog(@"found user: %@", array.firstObject);
        XCTAssert(array.count);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testSearchMultipleNames{
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Expect search result"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Expect search result"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"Expect search result"];
    NSString *phrase = @"Lee Zhang";
    NSLog(@"Search for %@", phrase);
    [[EWSocialManager sharedInstance] searchUserWithPhrase:phrase completion:^(NSArray *array, NSError *error){
        NSLog(@"found user: %lu", (unsigned long)array.count);
        XCTAssert(array.count);
        [expectation1 fulfill];
    }];
    
    phrase = @"Lee bug";
    NSLog(@"Search for %@", phrase);
    [[EWSocialManager sharedInstance] searchUserWithPhrase:phrase completion:^(NSArray *array, NSError *error){
        NSLog(@"found user: %lu", (unsigned long)array.count);
        XCTAssert(array.count);
        [expectation2 fulfill];
    }];
    
    phrase = @"Lee, bug, Zhang";
    NSLog(@"Search for %@", phrase);
    [[EWSocialManager sharedInstance] searchUserWithPhrase:phrase completion:^(NSArray *array, NSError *error){
        NSLog(@"found user: %ld", array.count);
        XCTAssert(array.count);
        [expectation3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testFindAddressBookFriends{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect to find adressbook friends"];
    [[EWSocialManager sharedInstance] findAddressbookUsersFromContactsWithCompletion:^(NSArray *array, NSError *error) {
        NSLog(@"Found %ld ab matched friends from server", array.count);
        if (!error) {
            [expectation fulfill];
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
    }];
}

@end
