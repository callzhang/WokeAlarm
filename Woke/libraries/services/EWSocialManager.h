//
//  EWSocialGraphManager.h
//  Woke
//
//  Created by Lei on 4/16/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWSocial.h"
@class EWPerson;
@interface EWSocialManager : NSObject

+ (EWSocialManager *)sharedInstance;

//Search
- (EWSocial *)socialGraphForPerson:(EWPerson *)person;

//- (void)testFindWithUsersCompletion:(void (^)(NSArray *users))completion;
//- (BOOL)hasAddressBookAccess;
- (void)loadAddressBookCompletion:(void (^)(NSArray *contacts, NSError *error))completion;

- (void)updateFriendshipTimeline;

//return an array of EWPerson
- (void)searchUserWithPhrase:(NSString *)phrase completion:(ArrayBlock)block;
@end
