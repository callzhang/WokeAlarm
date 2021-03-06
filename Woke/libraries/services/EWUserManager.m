	//
//  EWUserManager.m
//  EarlyWorm
//
//  Created by Lei on 1/3/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//


#import "EWStartUpSequence.h"
#import "EWUtil.h"
@import CoreLocation;

//model
#import "EWPerson.h"
#import "EWPersonManager.h"
#import "EWServer.h"
#import "EWAlarmManager.h"

//View
#import "EWLogInViewController.h"


//Util
#import "EWUtil.h"
#import "UIImageView+AFNetworking.h"
#import "ATConnect.h"

//social network
#import "EWSocial.h"
#import "EWSocialManager.h"
#import "EWAlarm.h"
#import "PFFacebookUtils.h"
#import "FacebookSDK.h"
#import "EWUIUtil.h"




@implementation EWUserManager

+ (EWUserManager *)sharedInstance{
    static EWUserManager *userManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userManager = [[EWUserManager alloc] init];
    });
    return userManager;
}

+ (void)login{
    
    if ([PFUser currentUser]) {
        //user already logged in
        NSLog(@"[a]Get Parse logged in user: %@", [PFUser currentUser].username);
        [EWUserManager loginWithServerUser:[PFUser currentUser] withCompletionBlock:NULL];
        
        //see if user is linked with fb
        if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
            [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    //fetch user in coredata cache(offline) with related objects
                    DDLogInfo(@"[b] Logged in to facebook");
                    
                }else if([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) {
                    // Since the request failed, we can check if it was due to an invalid session
                    DDLogInfo(@"The facebook session was expired");
                    [EWUserManager showLoginPanel];
                    
                }else{
                    DDLogInfo(@"Failed to login facebook, error: %@", error.description);
                    //[EWUserManager showLoginPanel];
                    [self handleFacebookException:error];
                    
                }
            }];
        }
        
    }else{
        //log in using local machine info
        [EWUserManager showLoginPanel];
    }
    
    
    //watch for login event
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoginEventHandler) name:EWAccountDidLoginNotification object:Nil];

}


+ (void)showLoginPanel{


//    if ([PFUser currentUser]) {
//        
//        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:[EWFirstTimeViewController new] animated:YES completion:NULL];
//    }else{
//        
//        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:[EWFirstTimeViewController new] animated:NO completion:NULL];
//    }
    
}


//login Core Data User with Server User (PFUser)
+ (void)loginWithServerUser:(PFUser *)user withCompletionBlock:(VoidBlock)completionBlock{

    //fetch or create
    EWPerson *person = [EWPerson findOrCreatePersonWithParseObject:user];
    
    //save me
    [EWSession sharedSession].currentUser = person;
    
    if ([EWSync sharedInstance].workingQueue.count == 0) {
        //if no pending uploads, refresh self
        [person refreshInBackgroundWithCompletion:NULL];
    }
    
    if (completionBlock) {
        DDLogInfo(@"[d] Run completion block.");
        completionBlock();
        
        //TODO:[[ATConnect sharedConnection] engage:@"login_success" fromViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
    }
    
    DDLogInfo(@"[c] Broadcast Person login notification");
    [[NSNotificationCenter defaultCenter] postNotificationName:EWAccountDidLoginNotification object:[EWPerson me] userInfo:@{kUserLoggedInUserKey:[EWPerson me]}];
    
    //if new user, link with facebook
    if([PFUser currentUser].isNew){
        [EWUserManager handleNewUser];
        //TODO:[[ATConnect sharedConnection] engage:@"new_user" fromViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
    }
}



//Depreciated: log in using local machine info
+ (void)loginWithDeviceIDWithCompletionBlock:(VoidBlock)block{
    //log out fb first
    [FBSession.activeSession closeAndClearTokenInformation];
    //get user default
    NSString *ADID = [[NSUserDefaults standardUserDefaults] objectForKey:kADIDKey];
    if (!ADID) {
        ADID = [EWUtil ADID];
        [[NSUserDefaults standardUserDefaults] setObject:ADID forKey:kADIDKey];
        NSLog(@"Stored new ADID: %@", ADID);
    }
    //get ADID
    NSArray *adidArray = [ADID componentsSeparatedByString:@"-"];
    //username
    NSString *username = [NSString stringWithFormat:@"EW%@", adidArray.firstObject];
    //password
    NSString *password = adidArray.lastObject;
    
    //try to log in
    [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
                                       
        if (user) {
            [EWUserManager loginWithServerUser:user withCompletionBlock:block];
            
        }else{
            NSLog(@"Creating new user: %@", error.description);
            //create new user
            PFUser *_user = [PFUser user];
            _user.username = username;
            _user.password = password;
            error = nil;
            [_user signUp:&error];
            if (!error) {
                [EWUserManager loginWithServerUser:_user withCompletionBlock:^{
                    if (block) {
                        block();
                    }
                }];
            }else{
                DDLogError(@"Failed to sign up new user: %@", error.description);
				[EWUIUtil showtext:@"Server not available, please try again."];
                [EWUserManager showLoginPanel];
            }
            
        }
        
    }];
}

+ (void)logout{
    //log out SM
    if ([PFUser currentUser]) {
        [PFUser logOut];
        DDLogInfo(@"Successfully logged out");
        //log out fb
        [FBSession.activeSession closeAndClearTokenInformation];
        //log in with device id
        //[self loginWithDeviceIDWithCompletionBlock:NULL];
        
        //login view
        [EWUserManager showLoginPanel];
        
    }else{
        //log out fb
        [FBSession.activeSession closeAndClearTokenInformation];
        //login view
        [EWUserManager showLoginPanel];
    };
    
    //remove all queue
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueDelete];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueInsert];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueUpdate];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueWorking];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueDownload];
    DDLogInfo(@"Cleaned local queue");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:EWAccountDidLogoutNotification object:self userInfo:nil];
    
}


+ (void)handleNewUser{
    [EWUserManager linkWithFacebook];
//    NSString *msg = [NSString stringWithFormat:@"Welcome %@ joining Woke!", [EWPerson me].name];
//    EWAlert(msg);
//    [EWServer broadcastMessage:msg onSuccess:NULL onFailure:NULL];
	[PFCloud call
}




//
////Danger Zone
//+ (void)purgeUserData{
//    DDLogDebug(@"Cleaning all cache and server data");
//    [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window.rootViewController.view animated:YES];
//    
//    //Alarm
//    [EWAlarmManager deleteAll];
//    //task
//    [[EWTaskManager sharedInstance] deleteAllTasks];
//    //media
//    //[EWMediaStore.sharedInstance deleteAllMedias];
//    //check
//    [[EWTaskManager sharedInstance ] checkScheduledNotifications];
//    
//    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].delegate.window.rootViewController.view animated:YES];
//    
//    [EWSync save];
//    //person
//    //me = nil;
//    
//    //alert
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clean Data" message:@"All data has been cleaned." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alert show];
//    //logout
//    //[EWUserManager logout];
//    
//    
//}


#pragma mark - location
+ (void)registerLocation{

    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        
        if (geoPoint.latitude == 0 && geoPoint.longitude == 0) {
            //NYC coordinate if on simulator
            geoPoint.latitude = 40.732019;
            geoPoint.longitude = -73.992684;
        }
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:geoPoint.latitude longitude:geoPoint.longitude];
        
        DDLogVerbose(@"Get user location with lat: %f, lon: %f", geoPoint.latitude, geoPoint.longitude);
        
        //reverse search address
        CLGeocoder *geoloc = [[CLGeocoder alloc] init];
        [geoloc reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *err) {
            
            [EWPerson me].lastLocation = location;
            
            if (err == nil && [placemarks count] > 0) {
                CLPlacemark *placemark = [placemarks lastObject];
                //get info
                [EWPerson me].city = placemark.locality;
                [EWPerson me].region = placemark.country;
            } else {
                NSLog(@"%@", err.debugDescription);
            }
            [EWSync save];

        }];
        
        
    }];
}

#pragma mark - FACEBOOK
+ (void)loginParseWithFacebookWithCompletion:(ErrorBlock)block{
    //login with facebook
    [PFFacebookUtils logInWithPermissions:[EWUserManager facebookPermissions] block:^(PFUser *user, NSError *error) {
        if (error) {
            [EWUserManager handleFacebookException:error];
            if (block) {
                block(error);
            }
        }
        else {
            [EWUserManager loginWithServerUser:[PFUser currentUser] withCompletionBlock:^{
                //background refresh
                if (block) {
                    DDLogInfo(@"[d] Run completion block.");
                    block(nil);
                }
            }];
        }
    }];
}


+ (void)updateFacebookInfo{
    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *data, NSError *error) {
            [EWUserManager handleFacebookException:error];
            //update with facebook info
            [EWUserManager updateUserWithFBData:data];
        }];
    }
}



+ (void)linkWithFacebook{
    NSParameterAssert([PFUser currentUser]);
    BOOL islinkedWithFb = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]];
    if (!islinkedWithFb) {
        [PFFacebookUtils unlinkUser:[PFUser currentUser]];
    }
    [PFFacebookUtils linkUser:[PFUser currentUser] permissions:[EWUserManager facebookPermissions] block:^(BOOL succeeded, NSError *error) {
        if (error) {
            DDLogError(@"Failed to get facebook info: %@", error.description);
            [EWUserManager handleFacebookException:error];
            return ;
        }
        
        //alert
        EWAlert(@"Facebook account linked!");
        
        //update current user with fb info
        [EWUserManager updateFacebookInfo];
    }];
}




//after fb login, fetch user managed object
+ (void)updateUserWithFBData:(NSDictionary<FBGraphUser> *)user{
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        EWPerson *person = [[EWPerson me] MR_inContext:localContext];
        
        NSParameterAssert(person);
        
        //name
        if ([person.name isEqualToString:kDefaultUsername] || person.name.length == 0) {
            person.name = user.name;
        }
        //email
        if (!person.email) person.email = user[@"email"];
        
        //birthday format: "01/21/1984";
        if (!person.birthday) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"mm/dd/yyyy";
            person.birthday = [formatter dateFromString:user[@"birthday"]];
        }
        //facebook link
        person.facebook = user.objectID;
        //gender
        person.gender = user[@"gender"];
        //city
        person.city = user.location[@"name"];
        //preference
        if(!person.preference){
            //new user
            person.preference = kUserDefaults;
        }
        
        if (!person.profilePic) {
            //download profile picture if needed
            //profile pic, async download, need to assign img to person before leave
            NSString *imageUrl = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large", user.objectID];
            
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
            UIImage *img = [UIImage imageWithData:data];
			if (!img) {
				img = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", arc4random_uniform(15)]];
			}
            person.profilePic = img;
        }
        
    }completion:^(BOOL success, NSError *error) {
        //update friends
        [EWUserManager getFacebookFriends];
    }];
}

+ (void)getFacebookFriends{
//    DDLogVerbose(@"Updating facebook friends");
//    //check facebook id exist
//    if (![EWPerson me].facebook) {
//        DDLogWarn(@"Current user doesn't have facebook ID, skip checking fb friends");
//        return;
//    }
//    
//    FBSessionState state = [FBSession activeSession].state;
//    if (state != FBSessionStateOpen && state != FBSessionStateOpenTokenExtended) {
//        
//        //session not open, need to open
//        DDLogVerbose(@"facebook session state: %d", state);
//        [EWUserManager openFacebookSessionWithCompletion:^{
//            DDLogVerbose(@"Facebook session opened: %d", [FBSession activeSession].state);
//            
//            [EWUserManager getFacebookFriends];
//        }];
//        
//        return;
//    }else{
//        
//        //get social graph of current user
//        //if not, create one
//        [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
//            EWPerson *localMe = [[EWPerson me] MR_inContext:localContext];
//            EWSocial *graph = [[EWSocialManager sharedInstance] socialGraphForPerson:localMe];
//            //skip if checked within a week
//            if (graph.facebookUpdated && abs([graph.facebookUpdated timeIntervalSinceNow]) < kSocialGraphUpdateInterval) {
//                DDLogVerbose(@"Facebook friends check skipped.");
//                return;
//            }
//            
//            //get the data
//            __block NSMutableDictionary *friends = [NSMutableDictionary new];
//            [EWUserManager getFacebookFriendsWithPath:@"/me/friends" withReturnData:friends];
//        } completion:^(BOOL success, NSError *error) {
//            //
//        }];
//        
//    }
    
}

+ (void)getFacebookFriendsWithPath:(NSString *)path withReturnData:(NSMutableDictionary *)friendsHolder{
//    [FBRequestConnection startWithGraphPath:path completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//        
//        DDLogVerbose(@"Got facebook friends list, start processing");
//        if (!error){
//            NSArray *friends = (NSArray *)result[@"data"];
//            NSString *nextPage = (NSString *)result[@"paging"][@"next"]	;
//            //parse
//            if (friends) {
//                for (NSDictionary *pair in friends) {
//                    NSString *fb_id = pair[@"id"];
//                    NSString *name = pair[@"name"];
//                    [friendsHolder setObject:name forKey:fb_id];
//                }
//            }
//            
//            //next page
//            if (nextPage) {
//                //continue loading facebook friends
//                //NSLog(@"Continue facebook friends request: %@", nextPage);
//                [self getFacebookFriendsWithPath:nextPage withReturnData:friendsHolder];
//            }else{
//                DDLogVerbose(@"Finished loading friends from facebook, transfer to social graph.");
//                EWSocial *graph = [[EWSocialManager sharedInstance] socialGraphForPerson:[EWPerson me]];
//                graph.facebookFriends = [friendsHolder copy];
//                graph.facebookUpdated = [NSDate date];
//                
//                //save
//                [EWSync save];
//            }
//            
//        } else {
//            // An error occurred, we need to handle the error
//            // See: https://developers.facebook.com/docs/ios/errors
//            
//            [EWUserManager handleFacebookException:error];
//        }
//    }];
    
}



+ (void)openFacebookSessionWithCompletion:(VoidBlock)block{
    
    [FBSession openActiveSessionWithReadPermissions:EWUserManager.facebookPermissions
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         
         if (error) {
             [EWUserManager handleFacebookException:error];
         }else if (block){
             block();
         }
     }];
}

+ (NSArray *)facebookPermissions{
    NSArray *permissions = @[@"basic_info",
                             @"user_location",
                             @"user_birthday",
                             @"email",
                             @"user_photos",
                             @"user_friends"];
    return permissions;
}


#pragma mark - Weibo SDK
//
//+ (void)registerWeibo{
//    // Weibo SDK
//    //EWWeiboManager *weiboMgr = [EWWeiboManager sharedInstance];
//    //[weiboMgr registerApp];
//}
//
//+ (void)didReceiveWeiboRequest:(WBBaseRequest *)request {
//    EWWeiboManager *weiboManager = [EWWeiboManager sharedInstance];
//    [weiboManager didReceiveWeiboRequest:request];
//}
//
//+ (void)didReceiveWeiboResponse:(WBBaseResponse *)response {
//    EWWeiboManager *weiboManager = [EWWeiboManager sharedInstance];
//    [weiboManager didReceiveWeiboResponse:response];
//}
//
//+  (void)didReceiveWeiboSDKResponse:(id)JsonObject err:(NSError *)error {
//    EWWeiboManager *weiboManager = [EWWeiboManager sharedInstance];
//    [weiboManager didReceiveWeiboSDKResponse:JsonObject err:error];
//}
//



@end
