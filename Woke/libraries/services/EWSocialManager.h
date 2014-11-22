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
- (EWSocial *)mySocialGraph;
- (EWSocial *)socialGraphForPerson:(EWPerson *)person;

//Create
- (EWSocial *)createSocialGraphForPerson:(EWPerson *)person;

//- (void)testFindWithUsersCompletion:(void (^)(NSArray *users))completion;
//- (BOOL)hasAddressBookAccess;
- (void)loadAddressBookCompletion:(void (^)(NSArray *contacts, NSError *error))completion;
@end
