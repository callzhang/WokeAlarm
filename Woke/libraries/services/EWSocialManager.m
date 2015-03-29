//
//  EWSocialGraphManager.m
//  Woke
//
//  Created by Lei on 4/16/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWSocialManager.h"
#import "EWPerson.h"
#import "EWPersonManager.h"
#import "NSArray+BlocksKit.h"
#import "EWSocial.h"
#import "FBKVOController.h"
#import <RHAddressBook/AddressBook.h>
#import "NSString+Extend.h"
#import "PFFacebookUtils.h"
#import "EWAccountManager.h"
#import "EWErrorManager.h"
#import "FBTweak.h"
#import "FBTweakInline.h"

FBTweakAction(@"Social Manager", @"Action", @"Get facebook friends", ^{
    [EWPerson mySocialGraph].facebookUpdated = nil;
    [[EWSocialManager sharedInstance] getFacebookFriendsWithCompletion:^{
        DDLogInfo(@"Got %lu facebook friends", [EWPerson mySocialGraph].facebookFriends.allKeys.count);
    }];
});

FBTweakAction(@"Social Manager", @"Action", @"Invite facebook friends", ^{
    [[EWSocialManager sharedInstance] inviteFacebookFriends];
});

FBTweakAction(@"Social Manager", @"Action", @"Invite facebook friends in web", ^{
    [EWSocialManager sharedInstance].forceInviteWithWeb = YES;
    [[EWSocialManager sharedInstance] inviteFacebookFriends];
});


@interface EWSocialManager()
@property (nonatomic, strong) RHAddressBook *addressBook;
@end

@implementation EWSocialManager

+ (EWSocialManager *)sharedInstance{
    static EWSocialManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!manager) {
            manager = [[EWSocialManager alloc] init];
            [manager.KVOController observe:[EWPerson me] keyPath:EWPersonRelationships.friends options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) block:^(id observer, id object, NSDictionary *change) {
                //add new friends to the friendship timeline
                [manager updateFriendshipTimeline];
                
                //test
                NSIndexSet *indices = [change objectForKey:NSKeyValueChangeIndexesKey];
                if (indices == nil)
                    return;
                DDLogVerbose(@"Obverved friends changed");
                [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                    if ([change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeInsertion) {
                        //insertion
                        DDLogVerbose(@"New friends");
                    }else if ([change[NSKeyValueChangeNewKey] integerValue] == NSKeyValueChangeRemoval){
                        //removal
                        DDLogVerbose(@"removed friends");
                    }else if ([change[NSKeyValueChangeNewKey] integerValue] == NSKeyValueChangeReplacement){
                        //replacement
                        DDLogVerbose(@"replaced friends");
                    }
                }];
            }];
        }
    });
    
    return manager;
}


- (void)updateFriendshipTimeline{
    EWAssertMainThread
    EWPerson *me = [EWPerson me];
    
    NSMutableDictionary *friendsActivityDic = me.socialGraph.friendshipTimeline?:[NSMutableDictionary new];
    //diff
    NSMutableSet *existingFriendIDsInTimeline = [NSMutableSet new];
    NSMutableSet *allFriendIDs = [[me.friends valueForKey:kParseObjectID] mutableCopy];
    for (NSArray *friends in friendsActivityDic.allValues) {
        [existingFriendIDsInTimeline addObjectsFromArray:friends];
    }
    [allFriendIDs minusSet:existingFriendIDsInTimeline];
    //get friends for today
    NSString *dateKey = [NSDate date].date2YYMMDDString;
    NSArray *friendedArray = friendsActivityDic[dateKey]?:[NSArray new];
    NSMutableSet *friendedSet = [NSMutableSet setWithArray:friendedArray];;
    //add new friends
    [friendedSet setByAddingObjectsFromSet:allFriendIDs];
    if (friendedSet.count == 0) {
        return;
    }
    //save
    friendsActivityDic[dateKey] = [friendedSet allObjects];
    me.socialGraph.friendshipTimeline = friendsActivityDic;
    [me.socialGraph save];
}


- (EWSocial *)socialGraphForPerson:(EWPerson *)person{
    NSParameterAssert(person.isMe);
    if (person.socialGraph) {
        return person.socialGraph;
    }
    if (!person.isMe) {
        return nil;
    }
	//try to find EWSocial from PO
    PFUser *user = (PFUser *)person.parseObject;
    PFObject *social = user[EWPersonRelationships.socialGraph];
    [social fetchIfNeededAndSaveToCache:nil];
    EWSocial *graph;
    //create
    if (social) {
        graph = (EWSocial *)[social managedObjectInContext:person.managedObjectContext];
    }else {
        graph = [EWSocial newSocialForPerson:person];
    }
    person.socialGraph = graph;
	
    return graph;
}

#pragma mark - Addressbook

- (RHAddressBook *)addressBook {
    if (!_addressBook) {
        _addressBook = [[RHAddressBook alloc] init];
    }
    return _addressBook;
}

- (NSArray *) addressPeople {
    return self.addressBook.people;
}

- (void)findAddressbookUsersInWokeWithCompletion:(ArrayBlock)completion {
    
    EWSocial *social = [EWPerson mySocialGraph];
    NSDate *lastChecked = social.addressBookUpdated;
    if (lastChecked.timeElapsed < 24 * 3600) {
        completion(social.addressBookRelatedUsers?:[NSArray array], nil);
        return;
    }
    
    
    //request for access
    switch ([RHAddressBook authorizationStatus]) {
        case RHAuthorizationStatusNotDetermined:{
            //request authorization
            [self.addressBook requestAuthorizationWithCompletion:^(bool granted, NSError *error) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self findAddressbookUsersInWokeWithCompletion:completion];
                    });
                }else{
                    completion(nil, error);
                }
            }];
        }
            return;
        case RHAuthorizationStatusDenied:{
            DDLogError(@"Addressbook authorization denied");
            NSError *error = [NSError errorWithDomain:@"com.wokealarm.woke" code:-1 userInfo:nil];
            completion(nil, error);
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
            return;
        default:
            break;
    }
    
    //get a list of PHPerson
    NSArray *contacts = [self.addressBook people];
    NSMutableArray *myContactFriends = [NSMutableArray new];
    NSMutableArray *contactsEmails = [NSMutableArray new];
    for (RHPerson *contact in contacts) {
        [contactsEmails addObjectsFromArray:contact.emails.values];
        for (NSString *email in contact.emails.values) {
            UIImage *thumbnail = contact.thumbnail;
            if (!thumbnail) {
                thumbnail = (id)[NSNull null];
            }
            [myContactFriends addObject:@{@"email": email, @"name": contact.name, @"image": thumbnail}];
        }
    }
    social.addressBookFriends = myContactFriends;
    
    //Update email to EWSocial
    [self getUsersWithEmails:contactsEmails completion:^(NSArray *people, NSError *error) {
        if (completion) {
            completion(people, error);
        }
        
        for (EWPerson *person in people) {
            if (![social.addressBookRelatedUsers containsObject:person.email]) {
                [social.addressBookRelatedUsers addObject:person.email];
            }
        }
        social.addressBookUpdated = [NSDate date];
        [social save];
    }];
}

- (NSArray *)addressBookRecordIDsWithEmail:(NSString *)email{
    NSArray *people = [self.addressBook peopleWithEmail:email];
    NSArray *recordIDs = [people bk_map:^id(RHPerson *person) {
        NSNumber *ID = @(person.recordID);
        return ID;
    }];
    return recordIDs;
}

#pragma mark - Search user with string
- (void)searchUserWithPhrase:(NSString *)phrase completion:(ArrayBlock)block{
    phrase = [phrase stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!phrase || phrase.length < 3) {
        block(@[], nil);
        return;
    }
    
    if (phrase.isEmail) {
        DDLogDebug(@"search for email");
        [self getUsersWithEmails:@[phrase] completion:^(NSArray *array, NSError *error) {
            block(array, error);
        }];
    }else{
        DDLogDebug(@"search for string");
        [self getUsersWithString:phrase completion:^(NSArray *array, NSError *error) {
            block(array, error);
        }];
    }
}

- (void)getUsersWithEmails:(NSArray *)emails completion:(ArrayBlock)completion {
    PFQuery *emailQ = [PFUser query];
    NSMutableArray *emails_ = [NSMutableArray array];
    for (NSString *email in emails) {
        [emails_ addObject:[email lowercaseString]];
    }
    [emailQ whereKey:EWPersonAttributes.email containedIn:emails_];
    [emailQ setLimit:50];
    //[emailQ findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    [EWSync findObjectsFromServerInBackgroundWithQuery:emailQ completion:^(NSArray *peopleInEmail, NSError *error) {
        if (completion) {
            completion(peopleInEmail, error);
        }
    }];
}

- (void)getUsersWithString:(NSString *)name completion:(ArrayBlock)completion {
    NSString *string = [name stringByReplacingOccurrencesOfString:@"," withString:@" "];
    NSArray *subStrings = [string componentsSeparatedByString:@" "];
    PFQuery *query;
    for (NSString *str in subStrings) {
        PFQuery *q1 = [[PFUser query] whereKey:@"searchString" containsString:str.lowercaseString];
        query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:q1, query, nil]];
    }
    [query setLimit:50];
    [EWSync findObjectsFromServerInBackgroundWithQuery:query completion:^(NSArray *people, NSError *error) {
        DDLogDebug(@"===> Search phrase %@ with result of %@", name, [people valueForKey:EWPersonAttributes.firstName]);

        if (completion) {
            completion(people, error);
        }
    }];
}

#pragma mark - Search facebook friends

- (void)getFacebookFriendsWithCompletion:(VoidBlock)block{
    DDLogVerbose(@"Updating facebook friends");
    //check facebook id exist
    if (![EWPerson me].facebookID) {
        DDLogWarn(@"Current user doesn't have facebook ID, skip checking fb friends");
        return;
    }
    
    FBSessionState state = [FBSession activeSession].state;
    if (state != FBSessionStateOpen && state != FBSessionStateOpenTokenExtended) {
        
        //session not open, need to open
        DDLogWarn(@"facebook session state: %lu", state);
        [[EWAccountManager sharedInstance] openFacebookSessionWithCompletion:^{
            DDLogInfo(@"Facebook session opened: %lu", [FBSession activeSession].state);
            
            [self getFacebookFriendsWithCompletion:block];
        }];
        
        return;
    }else{
        //get social graph of current user
        EWSocial *graph = [EWPerson mySocialGraph];
        //skip if checked within a week
        if (graph.facebookUpdated && abs([graph.facebookUpdated timeIntervalSinceNow]) < kSocialGraphUpdateInterval) {
            DDLogVerbose(@"Facebook friends check skipped.");
            if (block) {
                block();
            }
            return;
        }
        
        //get the data
        __block NSMutableDictionary *friends = [NSMutableDictionary new];
        [self getFacebookFriendsWithPath:@"/me/friends" withReturnData:friends withCompletion:block];
        
    }
}

- (void)getFacebookFriendsWithPath:(NSString *)path withReturnData:(NSMutableDictionary *)friendsHolder withCompletion:(VoidBlock)block{
    [FBRequestConnection startWithGraphPath:path completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if (!error){
            NSArray *friends = (NSArray *)result[@"data"];
            NSString *nextPage = (NSString *)result[@"paging"][@"next"]	;
            //parse
            if (friends) {
                DDLogVerbose(@"Got facebook friends list, start processing");
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
                [self getFacebookFriendsWithPath:nextPage withReturnData:friendsHolder withCompletion:block];
            }else{
                DDLogInfo(@"Finished loading %ld friends from facebook, save to social graph.", (unsigned long)friendsHolder.count);
                EWSocial *social = [[EWSocialManager sharedInstance] socialGraphForPerson:[EWPerson me]];
                social.facebookFriends = friendsHolder.mutableCopy;
                social.facebookUpdated = [NSDate date];
                
                //save
                [social save];
                
                //search for facebook related user
                [self findFacebookRelatedUsersWithCompletion:NULL];
                
                //completion
                if (block) {
                    block();
                }
            }
            
        } else {
            // An error occurred, we need to handle the error
            // See: https://developers.facebook.com/docs/ios/errors
            [EWErrorManager handleError:error];
        }
    }];
}

#pragma mark - Find related server users
- (void)findFacebookRelatedUsersWithCompletion:(ArrayBlock)block{
    //get list of fb id
    if (!block) return;
    EWSocial *social = [EWPerson mySocialGraph];
    NSArray *facebookIDs = social.facebookFriends.allKeys;
    //if my facebookFriends is empty, and woke has never serched for facebookFriends, start search for fbFriends
    if (facebookIDs.count == 0 && !social.facebookUpdated) {
        DDLogInfo(@"My social hasn't been updated for facebook friends. Get fb friends first and then redo find woke fb user.");
        [self getFacebookFriendsWithCompletion:^{
            [self findFacebookRelatedUsersWithCompletion:block];
        }];
        
        return;
    }
    PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([EWSocial class])];
    [query whereKey:EWSocialAttributes.facebookID containedIn:facebookIDs];
	NSSet *friendsFbIDs = [[EWPerson me] valueForKeyPath:[NSString stringWithFormat:@"%@.%@.%@", EWPersonRelationships.friends, EWPersonRelationships.socialGraph, EWSocialAttributes.facebookID]];
	if (friendsFbIDs.count) {
		[query whereKey:EWSocialAttributes.facebookID notContainedIn:friendsFbIDs.allObjects];
        DDLogInfo(@"Exclude friends's facebookID: %@", facebookIDs);
	}
	[query includeKey:EWSocialRelationships.owner];
    //[query setLimit:50];
    [EWSync findObjectsFromServerInBackgroundWithQuery:query completion:^(NSArray *socials, NSError *error) {
        DDLogDebug(@"===> Found %ld new facebook friends%@", (unsigned long)socials.count, [socials valueForKeyPath:@"owner.name"]);
        NSMutableArray *resultPeople = [NSMutableArray new];
        EWSocial *mySocial = [EWPerson mySocialGraph];
        for (EWSocial *social in socials) {
			EWPerson *person = social.owner;
            if (!person) {
                DDLogWarn(@"Failed to get owner for EWSocial (%@)", social.serverID);
            }
            [resultPeople addObject:person];
            
            //add facebook ID to social
            if (!mySocial.facebookRelatedUsers) mySocial.facebookRelatedUsers = [NSMutableArray new];
            if (![mySocial.facebookRelatedUsers containsObject:social.facebookID]) {
                [mySocial.facebookRelatedUsers addObject:social.facebookID];
            }
        }
        
        //save my social
        mySocial.facebookUpdated = [NSDate date];
        [mySocial save];
        
        //return
        if (block) {
            block(resultPeople.copy, error);
        }
    }];
}

- (NSURL *)getFacebookProfilePictureURLWithID:(NSString *)fid {
    NSString *imageUrl = [NSString stringWithFormat:@"http://graph.facebook.com/v2.2/%@/picture?type=large", fid];
    return [NSURL URLWithString:imageUrl];
}

- (void)inviteFacebookFriends{
    
    
    // Check if the Facebook app is installed and we can present
    // the message dialog
    FBLinkShareParams *params = [[FBLinkShareParams alloc] init];
    params.link = [NSURL URLWithString:@"http://WokeAlarm.com"];
    params.name = @"Wake me up, please?";
    params.caption = @"Woke";
    params.picture = [NSURL URLWithString:@"http://i.imgur.com/g3Qc1HN.png"];
    params.linkDescription = @"Please wake me up tomorrow on Woke.";
    
    // If the Facebook app is installed and we can present the share dialog
    if ([FBDialogs canPresentMessageDialogWithParams:params] && _forceInviteWithWeb == NO) {
        // Enable button or other UI to initiate launch of the Message Dialog
        [FBDialogs presentShareDialogWithLink:params.link name:params.name caption:params.caption description:params.linkDescription picture:params.picture clientState:nil handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
            if(error) {
                // An error occurred, we need to handle the error
                // See: https://developers.facebook.com/docs/ios/errors
                DDLogError(@"Error messaging link: %@", error.description);
            } else {
                // Success
                DDLogVerbose(@"Fb messager presentaed, result %@", results);
            }
        }];
    }  else {
        // Disable button or other UI for Message Dialog
        NSMutableDictionary *params =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
         @"Facebook SDK for iOS", @"name",
         @"Build great social apps and get more installs.", @"caption",
         @"The Facebook SDK for iOS makes it easier and faster to develop Facebook integrated iOS apps.", @"description",
         @"https://developers.facebook.com/ios", @"link",
         @"https://raw.github.com/fbsamples/ios-3.x-howtos/master/Images/iossdk_logo.png", @"picture",
         nil];
        
        // Invoke the dialog
        [FBWebDialogs presentFeedDialogModallyWithSession:nil parameters:params handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
            if (error) {
                // Error launching the dialog or publishing a story.
                NSLog(@"Error publishing story.");
            } else {
                if (result == FBWebDialogResultDialogNotCompleted) {
                    // User clicked the "x" icon
                    NSLog(@"User canceled story publishing.");
                } else {
                    // Handle the publish feed callback
                    NSDictionary *urlParams;// = [self parseURLParams:[resultURL query]];
                    if (![urlParams valueForKey:@"post_id"]) {
                        // User clicked the Cancel button
                        NSLog(@"User canceled story publishing.");
                    } else {
                        // User clicked the Share button
                        NSString *msg = [NSString stringWithFormat:
                                         @"Posted story, id: %@",
                                         [urlParams valueForKey:@"post_id"]];
                        NSLog(@"%@", msg);
                        // Show the result in an alert
                        [[[UIAlertView alloc] initWithTitle:@"Result"
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:@"OK!"
                                          otherButtonTitles:nil]
                         show];
                    }
                }
            }
        }];

        // Invite dislog always return cancelled, meaning we are not allowed to use?
//        [FBWebDialogs presentRequestsDialogModallyWithSession:nil message:params.linkDescription title:params.name parameters:nil handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
//            if (error) {
//                // Error launching the dialog or publishing a story.
//                NSLog(@"Error publishing story.");
//            } else {
//                if (result == FBWebDialogResultDialogNotCompleted) {
//                    // User clicked the "x" icon
//                    NSLog(@"User canceled story publishing.");
//                } else {
//                    // Handle the publish feed callback
//                    NSDictionary *urlParams;// = [self parseURLParams:[resultURL query]];
//                    if (![urlParams valueForKey:@"post_id"]) {
//                        // User clicked the Cancel button
//                        NSLog(@"User canceled story publishing.");
//                    } else {
//                        // User clicked the Share button
//                        NSString *msg = [NSString stringWithFormat:
//                                         @"Posted story, id: %@",
//                                         [urlParams valueForKey:@"post_id"]];
//                        NSLog(@"%@", msg);
//                        // Show the result in an alert
//                        [[[UIAlertView alloc] initWithTitle:@"Result"
//                                                    message:msg
//                                                   delegate:nil
//                                          cancelButtonTitle:@"OK!"
//                                          otherButtonTitles:nil]
//                         show];
//                    }
//                }
//            }
//        } friendCache:nil];
    }
}
@end
