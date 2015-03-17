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

- (EWSocial *)socialGraphForPerson:(EWPerson *)person;
- (void)updateFriendshipTimeline;

//Addressbook Search
- (void)findAddressbookUsersInWokeWithCompletion:(ArrayBlock)completion;
- (NSArray *)addressBookRecordIDsWithEmail:(NSString *)email;
//return an array of EWPerson
- (void)searchUserWithPhrase:(NSString *)phrase completion:(ArrayBlock)block;

//facebook friends search
- (void)getFacebookFriendsWithCompletion:(VoidBlock)block;
//match facebook friends on server to find related users
- (void)findFacebookRelatedUsersWithCompletion:(ArrayBlock)block;
- (NSURL *)getFacebookProfilePictureURLWithID:(NSString *)fid;
/**
 *  RHPeople
 */
- (NSArray *) addressPeople;

/**
 *  invitation from facebook
 */
- (void)inviteFacebookFriends;
@end