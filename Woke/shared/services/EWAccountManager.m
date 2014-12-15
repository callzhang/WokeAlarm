//
//  EWAccountManager.m
//  Woke
//
//  Created by Zitao Xiong on 13/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWAccountManager.h"
#import "PFFacebookUtils.h"
#import "EWPerson.h"
#import "EWErrorManager.h"
#import "EWSocialManager.h"
#import "FBSession.h"
#import "EWServer.h"
#import "ATConnect.h"

@interface EWAccountManager()
@property (nonatomic) BOOL isUpdatingFacebookInfo;
@end

@implementation EWAccountManager
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS(EWAccountManager)

//TODO: refactor to EWSession
+ (BOOL)isLoggedIn {
    return [[NSUserDefaults standardUserDefaults]  boolForKey:@"Loggin"];
}

+ (void)setLoggedIn:(BOOL)loggedIn {
    [[NSUserDefaults standardUserDefaults] setBool:loggedIn forKey:@"Loggin"];
    
    if (loggedIn) {
        DDLogInfo(@"[c] Broadcast Person login notification");
        [[NSNotificationCenter defaultCenter] postNotificationName:EWAccountDidLoginNotification object:[EWPerson me] userInfo:@{kUserLoggedInUserKey:[EWPerson me]}];
    }
}

- (void)loginFacebookCompletion:(void (^)(BOOL isNewUser, NSError *error))completion {
    //login with facebook
    [PFFacebookUtils logInWithPermissions:[[self class] facebookPermissions] block:^(PFUser *user, NSError *error) {
        if (user) {
            //fetch core data and set as current user (me)
            [self fetchCurrentUser:user];
            //refresh me if needed
            [self refreshEverythingIfNecesseryWithCompletion:^(BOOL isNewUser, NSError *err) {
                //if new user, link with facebook
                if([PFUser currentUser].isNew){
                    /**
                     *  Handle external event such as welcoming message and broadcasting new user to the community
                     */
                    //    [EWAccountManager linkWithFacebook];
                    NSString *msg = [NSString stringWithFormat:@"Welcome %@ joining Woke!", [EWPerson me].name];
                    EWAlert(msg);
                    [EWServer broadcastMessage:msg onSuccess:NULL onFailure:NULL];
                }
                
                //logged into the Core Data user
                if (completion) {
                    completion(isNewUser, err);
                }
            }];
        }
        else {
            if (error) {
                if (completion) {
                    completion(NO, error);
                }
            }
            else {
                NSError *error2 = [NSError errorWithDomain:EWErrorDomain code:-1 userInfo:@{EWErrorInfoDescriptionKey: @"User Cancelled Log"}];
                if (completion) {
                    completion(NO, error2);
                }
            }
        }
    }];
}

- (void)fetchCurrentUser:(PFUser *)user {
    EWPerson *person = [EWPerson findOrCreatePersonWithParseObject:user];
    [EWSession sharedSession].currentUser = person;
}

//login Core Data User with Server User (PFUser)
- (void)refreshEverythingIfNecesseryWithCompletion:(void (^)(BOOL isNewUser, NSError *error))completion{
    //here we have three scenarios:
    //1) Old user, everything should be update to date
    //2) New user, everything copied from defaul template and upload to server
    //3) Existing user but first time login on this phone, we need to download user data first and THEN execute login sequence
    
    //save me
    if (![[self class] isLoggedIn]){
        if ([EWSync sharedInstance].workingQueue.count == 0) {
            DDLogError(@"Upload queue is not empty when user logging in.");
        }
        //TODO: if no pending uploads, refresh self
        [[EWPerson me] refreshInBackgroundWithCompletion:^{
            if (completion) {
                //set login mark
                [[self class] setLoggedIn:YES];
                
                DDLogInfo(@"[d] Run completion block.");
                completion([PFUser currentUser].isNew, nil);
                
                [[ATConnect sharedConnection] engage:@"login_success" fromViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
            }
        }];
    }
    else {
        if (completion) {
            //set login mark
            [[self class] setLoggedIn:YES];
            completion([PFUser currentUser].isNew, nil);
        }
    }
}

- (void)updateFromFacebookCompletion:(void (^)(NSError *error))completion {
    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *data, NSError *error) {
            if (error) {
                [EWErrorManager handleError:error];
            }
            else {
                [self updateUserWithFBData:data];
            }
        }];
    }
    else {
        [PFFacebookUtils linkUser:[PFUser currentUser] permissions:[[self class] facebookPermissions] block:^(BOOL succeeded, NSError *error) {
            if (error) {
                if (completion) {
                    completion(error);
                }
                else {
                    [self updateFromFacebookCompletion:completion];
                }
            }
        }];
    }
}

- (void)logout {
    if ([PFUser currentUser]) {
        [PFUser logOut];
    }
    
    [EWSession sharedSession].currentUser = nil;
    
    [FBSession.activeSession closeAndClearTokenInformation];
    
    [[self class] setLoggedIn:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:EWAccountDidLogoutNotification object:self userInfo:nil];
}

#pragma mark - Facebook
- (void)updateMyFacebookInfo{
    if (self.isUpdatingFacebookInfo) {
        return;
    }
    self.isUpdatingFacebookInfo = YES;
    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *data, NSError *error) {
            if (error) {
                [EWAccountManager handleFacebookException:error];
            }
            
            //update with facebook info
            [[EWAccountManager shared] updateUserWithFBData:data];
        }];
    }
}

//after fb login, fetch user managed object
- (void)updateUserWithFBData:(NSDictionary<FBGraphUser> *)user{
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        EWPerson *person = [[EWPerson me] MR_inContext:localContext];
        
        NSParameterAssert(person);
        
        //name
        if ([person.name isEqualToString:EWPersonDefaultName] || person.name.length == 0) {
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
        [self getFacebookFriends];
        self.isUpdatingFacebookInfo = NO;
    }];
}

- (void)getFacebookFriends{
    DDLogVerbose(@"Updating facebook friends");
    //check facebook id exist
    if (![EWPerson me].facebook) {
        DDLogWarn(@"Current user doesn't have facebook ID, skip checking fb friends");
        return;
    }

    FBSessionState state = [FBSession activeSession].state;
    if (state != FBSessionStateOpen && state != FBSessionStateOpenTokenExtended) {

        //session not open, need to open
        DDLogVerbose(@"facebook session state: %lu", state);
        [self openFacebookSessionWithCompletion:^{
            DDLogVerbose(@"Facebook session opened: %lu", [FBSession activeSession].state);

            [self getFacebookFriends];
        }];

        return;
    }else{

        //get social graph of current user
        //if not, create one
        [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
            EWPerson *localMe = [[EWPerson me] MR_inContext:localContext];
            EWSocial *graph = [[EWSocialManager sharedInstance] socialGraphForPerson:localMe];
            //skip if checked within a week
            if (graph.facebookUpdated && abs([graph.facebookUpdated timeIntervalSinceNow]) < kSocialGraphUpdateInterval) {
                DDLogVerbose(@"Facebook friends check skipped.");
                return;
            }

            //get the data
            __block NSMutableDictionary *friends = [NSMutableDictionary new];
            [self getFacebookFriendsWithPath:@"/me/friends" withReturnData:friends];
        } completion:^(BOOL success, NSError *error) {
            //
        }];
        
    }
}

- (void)openFacebookSessionWithCompletion:(void (^)(void))block{
    
    [FBSession openActiveSessionWithReadPermissions:[EWAccountManager facebookPermissions]
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         
         if (error) {
            [EWErrorManager handleError:error];
         }else if (block){
             block();
         }
     }];
}

- (void)getFacebookFriendsWithPath:(NSString *)path withReturnData:(NSMutableDictionary *)friendsHolder{
    [FBRequestConnection startWithGraphPath:path completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {

        DDLogVerbose(@"Got facebook friends list, start processing");
        if (!error){
            NSArray *friends = (NSArray *)result[@"data"];
            NSString *nextPage = (NSString *)result[@"paging"][@"next"]	;
            //parse
            if (friends) {
                for (NSDictionary *pair in friends) {
                    NSString *fb_id = pair[@"id"];
                    NSString *name = pair[@"name"];
                    [friendsHolder setObject:name forKey:fb_id];
                }
            }

            //next page
            if (nextPage) {
                //continue loading facebook friends
                //NSLog(@"Continue facebook friends request: %@", nextPage);
                [self getFacebookFriendsWithPath:nextPage withReturnData:friendsHolder];
            }else{
                DDLogVerbose(@"Finished loading friends from facebook, transfer to social graph.");
                EWSocial *graph = [[EWSocialManager sharedInstance] socialGraphForPerson:[EWPerson me]];
                graph.facebookFriends = [friendsHolder copy];
                graph.facebookUpdated = [NSDate date];

                //save
                [EWSync save];
            }

        } else {
            // An error occurred, we need to handle the error
            // See: https://developers.facebook.com/docs/ios/errors
            
            [EWErrorManager handleError:error];
        }
    }];
}

+ (void)handleFacebookException:(NSError *)error{
    if (!error) {
        return;
    }
    NSString *alertText;
    NSString *alertTitle;
    // If the error requires people using an app to make an action outside of the app in order to recover
    
    if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
        alertTitle = @"Something went wrong";
        alertText = [FBErrorUtility userMessageForError:error];
        //[self showMessage:alertText withTitle:alertTitle];
    } else {
        
        // If the user cancelled login, do nothing
        if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
            //[MBProgressHUD hideHUDForView:[UIApplication sharedApplication].delegate.window.rootViewController.view animated:YES];
            DDLogInfo(@"User cancelled login");
            alertTitle = @"User Cancelled Login";
            alertText = @"Please Try Again";
            
            // Handle session closures that happen outside of the app
        } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
            alertTitle = @"Session Error";
            alertText = @"Your current session is no longer valid. Please log in again.";
            //[self showMessage:alertText withTitle:alertTitle];
            
            // Here we will handle all other errors with a generic error messageaccessToken:.
            // We recommend you check our Handling Errors guide for more information
            // https://developers.facebook.com/docs/ios/errors/
            
            // Clear this token
            [FBSession.activeSession closeAndClearTokenInformation];
        } else if (error.code == 5){
            if (![EWSync isReachable]) {
                DDLogError(@"No connection: %@", error.description);
            }else{
                
                DDLogError(@"Error %@", error.description);
                alertTitle = @"Something went wrong";
                alertText = @"Operation couldn't be finished. We appologize for this. It may caused by weak internet connection.";
            }
        } else {
            //Get more error information from the error
            NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
            
            // Show the user an error message
            alertTitle = @"Something went wrong";
            alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
            //[self showMessage:alertText withTitle:alertTitle];
            DDLogError(@"Failed to login fb: %@", error.description);
            
            // Clear this token
            [FBSession.activeSession closeAndClearTokenInformation];
        }
    }
    
    if (!alertTitle) return;
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:alertTitle
                              message:alertText
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
    
}


+ (NSArray *)facebookPermissions{
    NSArray *permissions = @[@"public_profile",
                             @"user_location",
                             @"user_birthday",
                             @"email",
                             @"user_photos",
                             @"user_friends"];
    return permissions;
}

#pragma mark - Geolocation

- (void)registerLocation{
    
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

@end
