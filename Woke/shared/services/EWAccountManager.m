
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
#import "AppDelegate.h"
#import "EWUIUtil.h"
#import "NSTimer+BlocksKit.h"
#import "EWStartUpSequence.h"
#import "INTULocationManager.h"
#import "FBKVOController.h"
#import <BlocksKit+UIKit.h>
#import "UIAlertView+BlocksKit.h"
#import "FBGraphLocation.h"
#import "FBGraphPlace.h"


FBTweakAction(@"AccountManager", @"Action", @"Purge Core Data", ^{
    if([EWAccountManager isLoggedIn]){
        [EWUIUtil showText:@"Please log out first"];
        return;
    }
    [UIAlertView bk_showAlertViewWithTitle:@"Confirm delete data" message:@"Are you sure to delete all local core data stack?" cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"YES"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex > 0){
            [MagicalRecord cleanUp];
        }
    }];
});


@import CoreLocation;

@interface EWAccountManager()
@property (nonatomic) BOOL isUpdatingFacebookInfo;
@property (nonatomic, strong) INTULocationManager *manager;
@end

@implementation EWAccountManager
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS(EWAccountManager)

+ (BOOL)isLoggedIn {
    return [PFUser currentUser] != nil;
}

- (void)loginFacebookCompletion:(ErrorBlock)completion {
    //login with facebook
    [PFFacebookUtils logInWithPermissions:[[self class] facebookPermissions] block:^(PFUser *user, NSError *error) {
        if (user) {
            //link if necessary
            if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
                [PFFacebookUtils linkUser:[PFUser currentUser] permissions:[[self class] facebookPermissions] block:^(BOOL succeeded, NSError *error){
                    DDLogInfo(@"Facebook account linked %@", succeeded?@"YES":@"NO");
                    if (error) [EWErrorManager handleError:error];
                }];
            }
            
            //fetch core data and set as current user (me)
            [self fetchCurrentUser:user];
            //refresh me if needed
            [self refreshEverythingIfNecesseryWithCompletion:^(NSError *err){
                //if new user, link with facebook
                if([PFUser currentUser].isNew){
                    [self updateMyFacebookInfoWithCompletion:^(NSError *error2) {
                        if (error2) {
                            [EWErrorManager handleError:error2];
                        } else {
                            //show success view on top view
                            [EWUIUtil showSuccessHUBWithString:@"Logged in"];
                        }
                        
                        //Handle external event such as welcoming message and broadcasting new user to the community
                        [self handleNewUser];
                    }];
                }
                
                //logged into the Core Data user
                if (completion) {
                    completion(err);
                }
            }];
        }
        else {
            if (error) {
                if (completion) {
                    completion(error);
                }
            }
            else {
                NSError *error2 = [NSError errorWithDomain:EWErrorDomain code:-1 userInfo:@{EWErrorInfoDescriptionKey: @"User Cancelled Log"}];
                if (completion) {
                    completion(error2);
                }
            }
        }
    }];
}

- (void)fetchCurrentUser:(PFUser *)user {
    EWPerson *person = [EWPerson findOrCreatePersonWithParseObject:user];
    [EWSession sharedSession].currentUser = person;
    [[EWSync sharedInstance] setCachedParseObject:user];
    
    //set up crashlytics user info
//    [Crashlytics setUserName:user.username];
//    [Crashlytics setUserEmail:user.email];
//    [Crashlytics setUserIdentifier:user.objectId];
//    [Crashlytics setObjectValue:user[@"firstName"] forKey:@"name"];
    
}

//login Core Data User with Server User (PFUser)
- (void)refreshEverythingIfNecesseryWithCompletion:(ErrorBlock)completion{

    //1) Sync user data
    //2) resume upload
    //3) login data check
    //4) post login notification

    TICK
    DDLogVerbose(@"Start sync user");
    //Delta sync
    [[EWStartUpSequence sharedInstance] syncUserWithCompletion:^(NSError *error){
        TOCK
        DDLogInfo(@"[a] Resume upload to server");
        [[EWSync sharedInstance] resumeUploadToServer];
        
        //startup sequence
        DDLogInfo(@"[b] Startup sequence");
        [[EWStartUpSequence sharedInstance] startupSequence];
        [[EWStartUpSequence sharedInstance] loginDataCheck];
        /*
        if ([EWSync sharedInstance].managedObjectsUpdating.count == 0) {
            [[EWStartUpSequence sharedInstance] loginDataCheck];
        }else{
            DDLogInfo(@"The item still updating is: %@", [EWSync sharedInstance].managedObjectsUpdating);
            [NSTimer bk_scheduledTimerWithTimeInterval:30 block:^(NSTimer *timer) {
                DDLogWarn(@"Start login data check after 30s");
                [[EWStartUpSequence sharedInstance] loginDataCheck];
            } repeats:NO];
        }*/
        
        //post notification
        DDLogInfo(@"[c] Broadcast Person login notification");
        [[NSNotificationCenter defaultCenter] postNotificationName:EWAccountDidLoginNotification object:[EWPerson me] userInfo:@{kUserLoggedInUserKey:[EWPerson me]}];
        if (completion) {
            DDLogDebug(@"[d] Run completion block.");
            completion(error);
        }
        
        [[ATConnect sharedConnection] engage:@"login_success" fromViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
    }];
}

- (void)logout {
    if ([PFUser currentUser]) {
        [PFUser logOut];
    }
    
    [EWSession sharedSession].currentUser = nil;
    
    [FBSession.activeSession closeAndClearTokenInformation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:EWAccountDidLogoutNotification object:self userInfo:nil];
}



/**
 *  Handle external event such as welcoming message and broadcasting new user to the community
 */
- (void)handleNewUser{
    //NSString *msg = [NSString stringWithFormat:@"Welcome %@ joining Woke!", [EWPerson me].name];
    //EWAlert(msg);
    //[EWServer broadcastMessage:msg onSuccess:NULL onFailure:NULL];
    NSString *email = [EWPerson me].email?:@"";
    NSString *facebookID = [EWPerson me].facebookID;
    NSParameterAssert(facebookID);
    [PFCloud callFunctionInBackground:@"handleNewUser" withParameters:@{@"userID": [EWPerson me].serverID, @"email": email, @"facebookID": facebookID} block:^(NSArray *relatedUsers, NSError *error) {
        if (error) {
            DDLogError(@"Failed to handle new user: %@", error.localizedDescription);
        } else {
            DDLogInfo(@"Handled new user and users delivered: %@", relatedUsers);
        }
    }];
}


#pragma mark - Facebook
- (void)updateMyFacebookInfoWithCompletion:(ErrorBlock)block{
    if (self.isUpdatingFacebookInfo) {
        if (block) {
            block(nil);
        }
        return;
    }
	//outdate
	BOOL outDated = NO;
	BOOL hasFacebook = NO;
	NSDate *lastUpdated = [[NSUserDefaults standardUserDefaults] valueForKey:kFacebookLastUpdated];
	if (!lastUpdated || lastUpdated.timeElapsed > 7*24*3600) {
		outDated = YES;
	}
	if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) hasFacebook = YES;
	
    if (outDated && hasFacebook) {
		self.isUpdatingFacebookInfo = YES;
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *data, NSError *error) {
            if (!data) {
                [EWErrorManager handleError:error];
            } else{
                //update with facebook info
                [[EWAccountManager shared] updateUserWithFBData:data];
            }
            if (block) {
                block(error);
            }
            
            self.isUpdatingFacebookInfo = NO;
        }];
    } else {
        DDLogInfo(@"Skipped updateing facebook info (last checked: %@)", lastUpdated.date2detailDateString);
        if (block) {
            block(nil);
        }
    }
}

//after fb login, fetch user managed object
- (void)updateUserWithFBData:(NSDictionary<FBGraphUser> *)user{
    EWSocial *sg = [EWPerson mySocialGraph];
    EWPerson *me = [EWPerson me];
    
    NSParameterAssert(me);
    
    //name
    if (!me.firstName) me.firstName = user.first_name;
    if (!me.lastName) me.lastName = user.last_name;
    
    //email
    NSString *email = user[@"email"];
    if (!me.email) me.email = [email lowercaseString];
    
    //birthday format: "01/21/1984";
    if (!me.birthday) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"mm/dd/yyyy";
        me.birthday = [formatter dateFromString:user[@"birthday"]];
    }
    //facebook link
    sg.facebookID = user.objectID;
    me.socialProfileID = [NSString stringWithFormat:@"%@%@", kFacebookIDPrefix, user.objectID];
    //gender
    me.gender = user[@"gender"];
    //location
    me.city = user.location.location.city;
    me.country = user.location.location.country;
    
    if (!me.profilePic) {
        //download profile picture if needed
        //profile pic, async download, need to assign img to person before leave
        [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
            EWPerson *localMe = [me MR_inContext:localContext];
            NSString *imageUrl = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large", user.objectID];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
            UIImage *img = [UIImage imageWithData:data];
            if (!img) {
                img = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", arc4random_uniform(15)]];
            }
            localMe.profilePic = img;
        }];
    }

    DDLogInfo(@"Updated user with facebook info");
    //set location
    if (![EWPerson me].location) {
        [self setProxymateLocationForPerson:[EWPerson me]];
    }
    //save time
    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"facebook_last_updated"];
    //update friends
    [[EWSocialManager sharedInstance] getFacebookFriendsWithCompletion:nil];
    //save
    [me save];
}


#pragma mark - Facebook tools
- (void)openFacebookSessionWithCompletion:(VoidBlock)block{
    
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
    self.manager = [INTULocationManager sharedInstance];
    INTULocationRequestID requestID = [self.manager requestLocationWithDesiredAccuracy:INTULocationAccuracyBlock timeout:60 delayUntilAuthorized:YES block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
        if (status == INTULocationStatusSuccess) {
            // Request succeeded, meaning achievedAccuracy is at least the requested accuracy, and
            // currentLocation contains the device's current location.
            DDLogInfo(@"Updated location %@ with accuracy of %.0fm", currentLocation, currentLocation.horizontalAccuracy);
            [self processLocation:currentLocation];
        }
        else if (status == INTULocationStatusTimedOut) {
            // Wasn't able to locate the user with the requested accuracy within the timeout interval.
            // However, currentLocation contains the best location available (if any) as of right now,
            // and achievedAccuracy has info on the accuracy/recency of the location in currentLocation.
            DDLogInfo(@"After 60s, we accept location %@ with accuracy of %.0fm", currentLocation, currentLocation.horizontalAccuracy);
            [self processLocation:currentLocation];
        }
		else if (status & (INTULocationStatusServicesDenied | INTULocationStatusServicesDisabled | INTULocationStatusServicesRestricted)){
			DDLogError(@"Failed to get location with status of %ld and location of %@", status, currentLocation);
			// An error occurred, more info is available by looking at the specific status returned.
			[UIAlertView bk_showAlertViewWithTitle:@"Location Services Not Enabled" message:@"The app can’t access your current location.\n\nTo enable, please turn on location access in the Settings app under Location Services." cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Go"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
				//set location
				if (buttonIndex == 1) {
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
				}
			}];
			
			[self setProxymateLocationForPerson:[EWPerson me]];
		}
        else {
			DDLogError(@"Failed to get location with status of %ld and location of %@", status, currentLocation);
			[EWUIUtil showText:@"Location service failed"];
			
			[self setProxymateLocationForPerson:[EWPerson me]];
        }
    }];
	
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self.manager forceCompleteLocationRequest:requestID];
        DDLogWarn(@"Woke exit when location request in progress");
    }];
}

- (void)processLocation:(CLLocation *)location{
    
    if (location.coordinate.latitude == 0 && location.coordinate.longitude == 0) {
        EWAlert(@"Using NYC coordinate on simulator");
        location = [[CLLocation alloc] initWithLatitude:40.732019 longitude:-73.992684];
    }
    [EWPerson me].location = location;
	//[[EWPerson me] save];
    
    //DDLogVerbose(@"Get user location with lat: %f, lon: %f", location.coordinate.latitude, location.coordinate.longitude);
    
    //reverse search address
    CLGeocoder *geoloc = [[CLGeocoder alloc] init];
    [geoloc reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *err) {
        
        if (!err && [placemarks count] > 0) {
            CLPlacemark *placemark = [placemarks lastObject];
            //get info
            [EWPerson me].city = placemark.locality;
            [EWPerson me].country = placemark.country;
        } else {
            DDLogWarn(@"%@", err.debugDescription);
        }
        [[EWPerson me] save];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserLocationUpdated object:nil];
    }];
}

- (void)setProxymateLocationForPerson:(EWPerson *)person{
    if (person.location) {
        DDLogWarn(@"Override location for person: %@", person.name);
    }
    CLGeocoder *geoloc = [[CLGeocoder alloc] init];
    [geoloc geocodeAddressString:[NSString stringWithFormat:@"%@, %@", person.city, person.country]  completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks.count) {
            CLPlacemark *pm = placemarks.firstObject;
            CLLocation *loc = pm.location;
            person.location = loc;
            DDLogInfo(@"Get proxymate location: %@", loc);
            [person save];
        }
    }];
}

@end
