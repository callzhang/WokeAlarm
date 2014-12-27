//
//  EWUserManager.h
//  EarlyWorm
//
//  Created by Lei on 1/3/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import <Parse/Parse.h>
#import "EWFirstTimeViewController.h"

@interface EWUserManager : NSObject
+ (EWUserManager *)sharedInstance;

#pragma mark - Login/Logout
/**
 Main point of login
 */
+ (void)login;
+ (void)showLoginPanel;

/**
 Login with PFUser for cached coredata info
 
 1) Get the Person MO, assign to me, save to local
 
 2) Handle new user
 
 3) Refresh person in background
 
 4) After finished refreshing, update fb info and broadcast user login
 */
+ (void)loginWithServerUser:(PFUser *)user withCompletionBlock:(VoidBlock)completionBlock;

/**
 Login with local plist or ADID
 */
+ (void)loginWithDeviceIDWithCompletionBlock:(VoidBlock)block;

/**
 Log in with temporary parse user
 */
//+ (void)loginWithTempUser:(VoidBlock)block;

/**
 Cache user's data
 */
//+ (void)cacheUserData;

//Log out
+ (void)logout;

//Handle new user
+ (void)handleNewUser;


#pragma mark - logged in tasks
+ (void)registerLocation;
//+ (void)updateLastSeen;

#pragma mark - facebook
//high level stuff
+ (void)loginParseWithFacebookWithCompletion:(void (^)(NSError *err))block;
//+ (void)loginUsingFacebookWithCompletion:(VoidBlock)block;
+ (void)updateUserWithFBData:(NSDictionary<FBGraphUser> *)user;
+ (void)getFacebookFriends;
+ (void)updateFacebookInfo;
//low level request
+ (NSArray *)facebookPermissions;
+ (void)openFacebookSessionWithCompletion:(VoidBlock)block;
+ (void)handleFacebookException:(NSError *)exception;
//+ (void)facebookSessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error;



#pragma mark - weibo
//+ (void)registerWeibo;




@end
