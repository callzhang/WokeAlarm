
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
#import "Crashlytics.h"
#import "FBKVOController.h"
#import <BlocksKit+UIKit.h>
#import "UIAlertView+BlocksKit.h"

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
            //fetch core data and set as current user (me)
            [self fetchCurrentUser:user];
            //refresh me if needed
            [self refreshEverythingIfNecesseryWithCompletion:^(NSError *err){
                //if new user, link with facebook
                if([PFUser currentUser].isNew){
                    /**
                     *  Handle external event such as welcoming message and broadcasting new user to the community
                     */
                    NSString *msg = [NSString stringWithFormat:@"Welcome %@ joining Woke!", [EWPerson me].name];
                    EWAlert(msg);
                    [EWServer broadcastMessage:msg onSuccess:NULL onFailure:NULL];
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
    [Crashlytics setUserName:user.username];
    [Crashlytics setUserEmail:user.email];
    [Crashlytics setUserIdentifier:user.objectId];
    [Crashlytics setObjectValue:user[@"firstName"] forKey:@"name"];
    
    //test
    [self.KVOController observe:person keyPath:EWPersonRelationships.unreadMedias options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        static NSUInteger lastUnreadCount;
        if ([EWPerson myUnreadMedias].count != lastUnreadCount) {
            lastUnreadCount = [EWPerson myUnreadMedias].count;
            DDLogInfo(@"Found unread medias changed to %ld", [EWPerson myUnreadMedias].count);
        }
    }];
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

//called on login
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:EWAccountDidLogoutNotification object:self userInfo:nil];
}

#pragma mark - Facebook
- (void)updateMyFacebookInfo{
    if (self.isUpdatingFacebookInfo) {
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
                return;
            }
            //update with facebook info
            [[EWAccountManager shared] updateUserWithFBData:data];
        }];
    } else {
        DDLogInfo(@"Skipped updateing facebook info (last checked: %@)", lastUpdated.date2detailDateString);
    }
}

//after fb login, fetch user managed object
- (void)updateUserWithFBData:(NSDictionary<FBGraphUser> *)user{
    EWSocial *sg = [EWPerson mySocialGraph];
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        EWPerson *localMe = [EWPerson meInContext:localContext];
        EWSocial *localSocial = [sg MR_inContext:localContext];
        
        NSParameterAssert(localMe);
        
        //name
        if (!localMe.firstName) localMe.firstName = user.first_name;
        if (!localMe.lastName) localMe.lastName = user.last_name;
        
        //email
        NSString *email = user[@"email"];
        if (!localMe.email) localMe.email = [email lowercaseString];
        
        //birthday format: "01/21/1984";
        if (!localMe.birthday) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"mm/dd/yyyy";
            localMe.birthday = [formatter dateFromString:user[@"birthday"]];
        }
        //facebook link
        localSocial.facebookID = user.objectID;
        //gender
        localMe.gender = user[@"gender"];
        //city
        localMe.city = user.location[@"name"];
        //preference
        if(!localMe.preference){
            //new user
            localMe.preference = kUserDefaults;
        }
        
        if (!localMe.profilePic) {
            //download profile picture if needed
            //profile pic, async download, need to assign img to person before leave
            NSString *imageUrl = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large", user.objectID];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
            UIImage *img = [UIImage imageWithData:data];
            if (!img) {
                img = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", arc4random_uniform(15)]];
            }
            localMe.profilePic = img;
        }
        
    }completion:^(BOOL success, NSError *error) {
        DDLogInfo(@"Updated user with facebook info");
        //set location
        if (![EWPerson me].location) {
            [self setProxymateLocationForPerson:[EWPerson me]];
        }
        //save time
		[[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"facebook_last_updated"];
        //update friends
        [[EWSocialManager sharedInstance] getFacebookFriendsWithCompletion:nil];
        self.isUpdatingFacebookInfo = NO;
    }];
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
        else {
            // An error occurred, more info is available by looking at the specific status returned.
            [UIAlertView bk_showAlertViewWithTitle:@"Location Services Not Enabled" message:@"The app can’t access your current location.\n\nTo enable, please turn on location access in the Settings app under Location Services." cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Go"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                //set location
                if (buttonIndex == 1) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }
            }];

            [self setProxymateLocationForPerson:[EWPerson me]];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self.manager cancelLocationRequest:requestID];
        DDLogWarn(@"Woke exit when location request in progress");
    }];
}

- (void)processLocation:(CLLocation *)location{
    
    if (location.coordinate.latitude == 0 && location.coordinate.longitude == 0) {
        EWAlert(@"Using NYC coordinate on simulator");
        location = [[CLLocation alloc] initWithLatitude:40.732019 longitude:-73.992684];
    }
    
    //DDLogVerbose(@"Get user location with lat: %f, lon: %f", location.coordinate.latitude, location.coordinate.longitude);
    
    //reverse search address
    CLGeocoder *geoloc = [[CLGeocoder alloc] init];
    [geoloc reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *err) {
        
        [EWPerson me].location = location;
        
        if (!err && [placemarks count] > 0) {
            CLPlacemark *placemark = [placemarks lastObject];
            //get info
            [EWPerson me].city = placemark.locality;
            [EWPerson me].country = placemark.country;
        } else {
            DDLogWarn(@"%@", err.debugDescription);
        }
        [[EWPerson me] save];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kUserLocationUpdated object:[EWPerson me]];
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
