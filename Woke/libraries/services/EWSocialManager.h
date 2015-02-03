//
//  EWSocialGraphManager.h
//  Woke
//
//  Created by Lei on 4/16/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWSocial.h"
#define kAddressBookChecked     @"addressbook_checked"

@class EWPerson;
@interface EWSocialManager : NSObject

+ (EWSocialManager *)sharedInstance;

- (EWSocial *)socialGraphForPerson:(EWPerson *)person;
- (void)updateFriendshipTimeline;

//Addressbook Search
- (void)findAddressbookUsersFromContactsWithCompletion:(ArrayBlock)completion;

//return an array of EWPerson
- (void)searchUserWithPhrase:(NSString *)phrase completion:(ArrayBlock)block;

//facebook friends search
- (void)getFacebookFriends;
//match facebook friends on server to find related users
- (void)findFacebookRelatedUsersWithCompletion:(ArrayBlock)block;
- (NSURL *)getFacebookProfilePictureURLWithID:(NSString *)fid;
@end