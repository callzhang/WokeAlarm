//
//  EWAccountManager.h
//  Woke
//
//  Created by Zitao Xiong on 13/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDSingleton.h"
#define kFacebookLastUpdated        @"facebook_last_updated"
#define kUserRelationSyncRequired   @[@"alarms", @"friends", @"socialGraph"]//list of relations that must be synced before the rest of the application execution
extern NSString * const kUserSyncCompleted;

@interface EWAccountManager : NSObject <CLLocationManagerDelegate>
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(EWAccountManager);

- (void)loginFacebookCompletion:(ErrorBlock)completion;
- (void)updateFromFacebookCompletion:(void (^)(NSError *error))completion;
- (void)fetchCurrentUser:(PFUser *)user;
- (void)refreshEverythingIfNecesseryWithCompletion:(ErrorBlock)completion;
+ (BOOL)isLoggedIn;
- (void)logout;

//tools
- (void)updateMyFacebookInfo;
- (void)registerLocation;
- (void)openFacebookSessionWithCompletion:(VoidBlock)block;

// sync user
/**
 *  Sync user at start up. Send local object ID and updatedAt. When returned from server, update all returned objects.
 *
 *  @param info Dictionary with first level: 1) relation 2) {objectID: updatedAt}
 */
- (void)syncUserWithCompletion:(ErrorBlock)block;
@end
