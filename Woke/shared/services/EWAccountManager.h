//
//  EWAccountManager.h
//  Woke
//
//  Created by Zitao Xiong on 13/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDSingleton.h"


@interface EWAccountManager : NSObject
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(EWAccountManager);

- (void)loginFacebookCompletion:(void (^)(BOOL isNewUser, NSError *error))completion;
- (void)updateFromFacebookCompletion:(void (^)(NSError *error))completion;
- (void)fetchCurrentUser:(PFUser *)user;
- (void)refreshEverythingIfNecesseryWithCompletion:(void (^)(BOOL isNewUser, NSError *error))completion;
+ (BOOL)isLoggedIn;
- (void)logout;

//tools
- (void)updateMyFacebookInfo;
- (void)registerLocation;
@end
