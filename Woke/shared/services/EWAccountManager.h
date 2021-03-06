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

@interface EWAccountManager : NSObject <CLLocationManagerDelegate>
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(EWAccountManager);

- (void)loginFacebookCompletion:(ErrorBlock)completion;
//- (void)updateFromFacebookCompletion:(void (^)(NSError *error))completion;
- (void)fetchCurrentUser:(PFUser *)user;
- (void)refreshEverythingIfNecesseryWithCompletion:(ErrorBlock)completion;
+ (BOOL)isLoggedIn;
- (void)logout;

//tools
- (void)updateMyFacebookInfoWithCompletion:(ErrorBlock)block;
- (void)registerLocation;
- (void)openFacebookSessionWithCompletion:(VoidBlock)block;

@end