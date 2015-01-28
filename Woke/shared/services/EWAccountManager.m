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
@import CoreLocation;

@interface EWAccountManager()
@property (nonatomic) BOOL isUpdatingFacebookInfo;
@property (nonatomic, strong) CLLocationManager *manager;
@end

@implementation EWAccountManager
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS(EWAccountManager)

//TODO: refactor to EWSession
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
}

//login Core Data User with Server User (PFUser)
- (void)refreshEverythingIfNecesseryWithCompletion:(ErrorBlock)completion{
    //here we have three scenarios:
    //1) Old user, everything should be update to date
    //2) New user, everything copied from defaul template and upload to server
    //3) Existing user but first time login on this phone, we need to download user data first and THEN execute login sequence
    TICK
    DDLogVerbose(@"Start sync user");
    //Delta sync
    [[EWAccountManager shared] syncUserWithCompletion:^(NSError *error){
        TOCK
        [[EWSync sharedInstance] resumeUploadToServer];
        DDLogInfo(@"[c] Broadcast Person login notification");
        
        //startup sequence
        [[EWStartUpSequence sharedInstance] loginDataCheck];
        
        //post notification
        [[NSNotificationCenter defaultCenter] postNotificationName:EWAccountDidLoginNotification object:[EWPerson me] userInfo:@{kUserLoggedInUserKey:[EWPerson me]}];
        if (completion) {
            
            DDLogDebug(@"[d] Run completion block.");
            completion(error);
        }
        
        [[ATConnect sharedConnection] engage:@"login_success" fromViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
    }];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:EWAccountDidLogoutNotification object:self userInfo:nil];
}

#pragma mark - Facebook
- (void)updateMyFacebookInfo{
    if (self.isUpdatingFacebookInfo) {
        return;
    }
	//outdate
	BOOL outDated = NO;
	BOOL needUpdate = NO;
	BOOL hasFacebook = NO;
	NSDate *lastUpdated = [[NSUserDefaults standardUserDefaults] valueForKey:kFacebookLastUpdated];
	if (!lastUpdated || lastUpdated.timeElapsed > 7*24*3600) {
		outDated = YES;
	}
	if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) hasFacebook = YES;
	if (![EWPerson me].firstName || ![EWPerson mySocialGraph]) {
		needUpdate = YES;
	}
	
    if ((outDated || needUpdate) && hasFacebook) {
		self.isUpdatingFacebookInfo = YES;
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
    EWSocial *sg = [EWPerson mySocialGraph];
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        EWPerson *localMe = [EWPerson meInContext:localContext];
        EWSocial *localSocial = [sg MR_inContext:localContext];
        
        NSParameterAssert(localMe);
        
        //name
        if (!localMe.firstName) localMe.firstName = user.first_name;
        if (!localMe.lastName) localMe.lastName = user.last_name;
        
        //email
        if (!localMe.email) localMe.email = user[@"email"];
        
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
        
        //set location
        if (![EWPerson me].location) {
            [self setProxymateLocationForPerson:[EWPerson me]];
        }
        //save time
		[[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"facebook_last_updated"];
        //update friends
        [self getFacebookFriends];
        self.isUpdatingFacebookInfo = NO;
    }];
}

- (void)getFacebookFriends{
    DDLogVerbose(@"Updating facebook friends");
    //check facebook id exist
    if (![EWPerson me].socialGraph.facebookID) {
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
            EWPerson *localMe = [EWPerson meInContext:localContext];
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
                [graph save];
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
    self.manager = [CLLocationManager new];
    self.manager.delegate = self;
    if ([self.manager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            [self.manager requestWhenInUseAuthorization];
        } else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] ==kCLAuthorizationStatusRestricted){
            //need pop alert
            DDLogError(@"Location service disabled");
            EWAlert(@"Location service is disabled. To find the best match around your area, please enable location service in settings.")
            [self setProxymateLocationForPerson:[EWPerson me]];
        }else{
            [self.manager startUpdatingLocation];
        }
    }else{
        [self.manager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusDenied:
            DDLogWarn(@"kCLAuthorizationStatusDenied");
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Location Services Not Enabled" message:@"The app can’t access your current location.\n\nTo enable, please turn on location access in the Settings app under Location Services." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            [self setProxymateLocationForPerson:[EWPerson me]];
        }
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            DDLogInfo(@"kCLAuthorizationStatusAuthorizedWhenInUse");
            manager.desiredAccuracy = kCLLocationAccuracyBest;
            manager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
            [manager startUpdatingLocation];
            
        }
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        {
            DDLogInfo(@"kCLAuthorizationStatusAuthorizedAlways");
            manager.desiredAccuracy = kCLLocationAccuracyBest;
            manager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
            [manager startUpdatingLocation];
        }
            break;
        case kCLAuthorizationStatusNotDetermined:
            DDLogInfo(@"kCLAuthorizationStatusNotDetermined");
            break;
        case kCLAuthorizationStatusRestricted:
            DDLogInfo(@"kCLAuthorizationStatusRestricted");
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    static CLLocation *loc;
    static NSTimer *locationTimeOut;
    loc = locations.lastObject;
    
    if (loc.horizontalAccuracy <100 && loc.verticalAccuracy < 100) {
        //bingo
        [manager stopUpdatingLocation];
        [locationTimeOut invalidate];
        [self processLocation:loc];
    } else if (!locationTimeOut) {
        locationTimeOut = [NSTimer bk_scheduledTimerWithTimeInterval:300 block:^(NSTimer *timer) {
            DDLogInfo(@"After 300s, we accept location with accuracy of %.0fm", loc.horizontalAccuracy);
            [manager stopUpdatingLocation];
            [self processLocation:loc];
        } repeats:NO];
    }
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

#pragma mark - Sync user
- (void)syncUserWithCompletion:(ErrorBlock)block{
    EWAssertMainThread
    NSString *userKey = @"user";
    
    //generate info dic
    EWPerson *me = [EWPerson me];
    NSMutableDictionary *graph = [NSMutableDictionary new];
    //if no date available for me, it must be up to date.
    if (me.updatedAt) {
        graph[userKey] = @{me.objectId: me.updatedAt};
    } else {
		//Even though there might be pending changes, but the fact that local user missing update time is a sign of bad run from last session, therefore we should resync from server
        DDLogWarn(@"User %@ has no updatedAt, using current time", me.name);
        graph[userKey] = @{me.objectId: [NSDate dateWithTimeIntervalSince1970:0]};
    }
	graph[userKey] = @{me.objectId: me.updatedAt?:[NSDate date]};
    //get the updated objects
    NSSet *workingObjects = [EWSync sharedInstance].workingQueue;
    workingObjects = [workingObjects setByAddingObjectsFromSet:[EWSync sharedInstance].insertQueue];
    
    //enumerate
    [me.entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *relation, BOOL *stop) {
        if ([relation.destinationEntity.name isEqualToString:kSyncUserClass]) {
            //skip user class
            return;
        }
        id objects = [me valueForKey:key];
        if (objects) {
            if ([relation isToMany]) {
                NSMutableDictionary *related = [NSMutableDictionary new];
                for (EWServerObject *SO in objects) {
                    if (!SO.objectId) {
                        //skip
                    }
                    else if ([workingObjects containsObject:SO]) {
                        //has change, do not update from server, use current time
                        //or has not updated to Server, meaning it will uploaded with newer data, use current time
                        related[SO.objectId] = [NSDate date];
                    }
                    else if (SO.updatedAt){
                        related[SO.objectId] = SO.updatedAt;
                    }
                }
                //add the graph to the info dic
                graph[key] = related;
            }
            else {
                //to-one relation
                EWServerObject *SO = (EWServerObject *)objects;
                if (!SO.objectId) {
                    //skip
                }
                else if ([workingObjects containsObject:SO]) {
                    //has change, do not update from server, use current time
                    //or has not updated to Server, meaning it will uploaded with newer data, use current time
                    graph[key] = @{SO.objectId: [NSDate date]};
                }
                else if (SO.updatedAt){
                    graph[key] = @{SO.objectId: SO.updatedAt};
                }else{
                    graph[key] = @{};
                }
            }
        }else{
            graph[key] = @0;
        }
    }];
    
    //send to cloud
    [PFCloud callFunctionInBackground:@"syncUser" withParameters:graph block:^(NSDictionary *POGraph, NSError *error) {
        DDLogInfo(@"Server returned sync info keys: %@", POGraph.allKeys);
        if (error) {
            block(error);
            return;
        }
        //expecting a dictionary of objects needed to update
        //return graph level: 1) relation name 2) Array of PFObjects or PFObject
        [POGraph enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            if ([key isEqualToString:userKey]) {
                [[EWSync sharedInstance] setCachedParseObject:obj];
            }
            NSRelationshipDescription *relation = me.entity.relationshipsByName[key];
            if (!relation || ![obj isKindOfClass:[PFObject class]]) return;
            //save PO first
            if (relation.isToMany) {
                for (PFObject *PO in obj) {
                    [[EWSync sharedInstance] setCachedParseObject:PO];
                }
            }else{
                [[EWSync sharedInstance] setCachedParseObject:(PFObject *)obj];
            }
        }];
        
        [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
            EWPerson *localMe = [me MR_inContext:localContext];
            [POGraph enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
                if ([key isEqualToString:@"delete"]) {
                    //delete all objects in this Dictionary
                    [(NSDictionary *)obj enumerateKeysAndObjectsUsingBlock:^(NSString *objectId, NSString *relationName, BOOL *stop2) {
                        NSRelationshipDescription *relation =  localMe.entity.relationshipsByName[relationName];
                        NSString *className = relation.destinationEntity.name;
                        EWServerObject *SO = (EWServerObject *)[NSClassFromString(className) MR_findFirstByAttribute:kParseObjectID withValue:objectId inContext:localContext];
						if (relation.isToMany) {
							NSMutableSet *related = [localMe valueForKey:relationName];
							[related removeObject:SO];
							[localMe setValue:related forKey:relationName];
						} else {
							[localMe setValue:nil forKey:relationName];
						}
                    }];
                    return;
				}else if ([key isEqualToString:userKey]){
					//update me
					[localMe assignValueFromParseObject:obj];
                    return;
				}
					
                NSRelationshipDescription *relation = localMe.entity.relationshipsByName[key];
                if (!relation) return;
                
                //update SO
                if (relation.isToMany) {
                    NSArray *objects = (NSArray *)obj;
                    NSMutableSet *relatedSO = [localMe mutableSetValueForKey:key];
                    for (PFObject *PO in objects) {
                        if(!PO.isDataAvailable) {
                            DDLogError(@"Returned PO without data: %@", PO);
                            [PO fetch];
                        }
                        EWServerObject *SO = [PO managedObjectInContext:localContext];
                        [SO updateValueAndRelationFromParseObject:PO];
                        if (![relatedSO containsObject:SO]) {
                            //add relation
                            [relatedSO addObject:SO];
                            [localMe setValue:relatedSO.copy forKey:key];
                            DDLogVerbose(@"+++> Added relation Me->%@(%@)", key, PO.objectId);
                        }
                    }
                }else{
                    //to one
                    EWServerObject *SO = [(PFObject *)obj managedObjectInContext:localContext];
                    [SO updateValueAndRelationFromParseObject:obj];
                    if (![localMe valueForKey:key]) {
                        DDLogVerbose(@"+++> Added relation Me->%@(%@)", key, SO.objectId);
                    }
                    [localMe setValue:SO forKey:key];
                }
            }];
			
			localMe.updatedAt = [NSDate date];
        } completion:^(BOOL contextDidSave, NSError *error2) {
            if (!error2) {
                DDLogDebug(@"========> Finished user syncing <=========");
                block(nil);
            }else{
                DDLogError(@"Failed to sync user: %@", error2.description);
                block(error2);
            }
            
        }];
        
        
    }];
}

@end
