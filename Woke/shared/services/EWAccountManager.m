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

NSString * const EWAccountManagerDidLoginNotification = @"EWAccountManagerDidLoginNotification";
NSString * const EWAccountManagerDidLogoutNotification = @"EWAccountManagerDidLogoutNotification";

@interface EWAccountManager()
@end

@implementation EWAccountManager
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS(EWAccountManager)


+ (BOOL)isLoggedIn {
    return [PFUser currentUser] != nil;
}

- (void)loginFacebookCompletion:(void (^)(BOOL isNewUser, NSError *error))completion {
    //login with facebook
    [PFFacebookUtils logInWithPermissions:[[self class] facebookPermissions] block:^(PFUser *user, NSError *error) {
        if (!user) {
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
        else {
            [self resumeCoreDataUserWithServerUser:user withCompletion:^(BOOL isNewUser, NSError *err) {
                //logged into the Core Data user
            }];
        }
    }];
}

//login Core Data User with Server User (PFUser)
- (void)resumeCoreDataUserWithServerUser:(PFUser *)user withCompletion:(void (^)(BOOL isNewUser, NSError *error))completion{
    
    //fetch or create
    EWPerson *person = [EWPerson findOrCreatePersonWithParseObject:user];
    
    //save me
    [EWSession sharedSession].currentUser = person;
    
    if ([EWSync sharedInstance].workingQueue.count == 0 && person.changedKeys.count == 0) {
        //if no pending uploads, refresh self
        [person refreshInBackgroundWithCompletion:NULL];
    }
    
    if (completion) {
        DDLogInfo(@"[d] Run completion block.");
        completion([PFUser currentUser].isNew, nil);
        
        //TODO:[[ATConnect sharedConnection] engage:@"login_success" fromViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
    }
    
    DDLogInfo(@"[c] Broadcast Person login notification");
    [[NSNotificationCenter defaultCenter] postNotificationName:EWAccountManagerDidLoginNotification object:[EWPerson me] userInfo:@{kUserLoggedInUserKey:[EWPerson me]}];
    
    //if new user, link with facebook
    if([PFUser currentUser].isNew){
        [EWAccountManager handleNewUser];
        //TODO:[[ATConnect sharedConnection] engage:@"new_user" fromViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
    }
}

- (void)updateFromFacebookCompletion:(void (^)(NSError *error))completion {
    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *data, NSError *error) {
            if (error) {
                [EWErrorManager handleError:error];
            }
            else {
                [[self class] updateUserWithFBData:data];
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
    
    //remove all queue
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueDelete];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueInsert];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueUpdate];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueWorking];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueRefresh];
    DDLogInfo(@"Cleaned local queue");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:EWAccountManagerDidLogoutNotification object:self userInfo:nil];
}
#pragma mark - Facebook
//after fb login, fetch user managed object
+ (void)updateUserWithFBData:(NSDictionary<FBGraphUser> *)user{
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
    }];
}

+ (void)getFacebookFriends{
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

+ (void)openFacebookSessionWithCompletion:(void (^)(void))block{
    
    [FBSession openActiveSessionWithReadPermissions:self.facebookPermissions
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

+ (void)getFacebookFriendsWithPath:(NSString *)path withReturnData:(NSMutableDictionary *)friendsHolder{
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


#pragma mark - Tools
+ (NSArray *)facebookPermissions{
    NSArray *permissions = @[@"public_profile",
                             @"user_location",
                             @"user_birthday",
                             @"email",
                             @"user_photos",
                             @"user_friends"];
    return permissions;
}



+ (void)handleNewUser{
//    [EWAccountManager linkWithFacebook];
    NSString *msg = [NSString stringWithFormat:@"Welcome %@ joining Woke!", [EWPerson me].name];
    EWAlert(msg);
    [EWServer broadcastMessage:msg onSuccess:NULL onFailure:NULL];
}
@end
