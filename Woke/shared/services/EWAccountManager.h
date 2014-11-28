//
//  EWAccountManager.h
//  Woke
//
//  Created by Zitao Xiong on 13/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDSingleton.h"

extern NSString * const EWAccountManagerDidLoginNotification;
extern NSString * const EWAccountManagerDidLogoutNotification;


@interface EWAccountManager : NSObject
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(EWAccountManager);

- (void)loginFacebookCompletion:(void (^)(BOOL isNewUser, NSError *error))completion;
- (void)updateFromFacebookCompletion:(void (^)(NSError *error))completion;
- (void)resumeCoreDataUserWithServerUser:(PFUser *)user withCompletion:(void (^)(BOOL isNewUser, NSError *error))completion;
+ (BOOL)isLoggedIn;
@end
