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
	
    EWSocial *graph = [EWSocial newSocialForPerson:person];
	if (person.isMe) {
        //update facebook friends
	}
    return graph;
}

#pragma mark - Addressbook

- (RHAddressBook *)addressBook {
    if (!_addressBook) {
        _addressBook = [[RHAddressBook alloc] init];
    }
    return _addressBook;
}

- (void)findAddressbookUsersFromContactsWithCompletion:(ArrayBlock)completion {
    
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
                        [self findAddressbookUsersFromContactsWithCompletion:completion];
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
            [myContactFriends addObject:@{@"email": email, @"name": contact.name}];
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
    if (!phrase || phrase.length == 0) {
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
    [EWSync findParseObjectInBackgroundWithQuery:emailQ completion:^(NSArray *objects, NSError *error) {
        NSMutableArray *resultPeople = [NSMutableArray new];
        for (PFUser *user in objects) {
            EWPerson *person = (EWPerson *)[user managedObjectInContext:mainContext];
            [resultPeople addObject:person];
        }
        if (completion) {
            completion(resultPeople, error);
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
    
    //[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    [EWSync findParseObjectInBackgroundWithQuery:query completion:^(NSArray *objects, NSError *error) {
        DDLogDebug(@"===> Search phrase %@ with result of %@", name, [objects valueForKey:EWPersonAttributes.firstName]);
        NSMutableArray *resultPeople = [NSMutableArray new];
        for (PFUser *user in objects) {
            EWPerson *person = (EWPerson *)[user managedObjectInContext:mainContext];
            [resultPeople addObject:person];
        }
        if (completion) {
            completion(resultPeople, error);
        }
    }];
}

#pragma mark - Search facebook friends

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
        [[EWAccountManager sharedInstance] openFacebookSessionWithCompletion:^{
            DDLogVerbose(@"Facebook session opened: %lu", [FBSession activeSession].state);
            
            [self getFacebookFriends];
        }];
        
        return;
    }else{
        //get social graph of current user
        EWSocial *graph = [EWPerson mySocialGraph];
        //skip if checked within a week
        if (graph.facebookUpdated && abs([graph.facebookUpdated timeIntervalSinceNow]) < kSocialGraphUpdateInterval) {
            DDLogVerbose(@"Facebook friends check skipped.");
            return;
        }
        
        //get the data
        __block NSMutableDictionary *friends = [NSMutableDictionary new];
        [self getFacebookFriendsWithPath:@"/me/friends" withReturnData:friends];
        
    }
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
                DDLogInfo(@"Finished loading %ld friends from facebook, transfer to social graph.", friendsHolder.count);
                EWSocial *graph = [[EWSocialManager sharedInstance] socialGraphForPerson:[EWPerson me]];
                graph.facebookFriends = friendsHolder.mutableCopy;
                graph.facebookUpdated = [NSDate date];
                
                //save
                [graph save];
                
                //search for facebook related user
                [self findFacebookRelatedUsersWithCompletion:NULL];
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
    EWSocial *social = [EWPerson mySocialGraph];
    NSArray *facebookIDs = social.facebookFriends.allKeys;
    if (facebookIDs.count == 0 || social.facebookUpdated.timeElapsed < 24 * 3600) {
        block(social.facebookRelatedUsers?:[NSArray array], nil);
        return;
    }
    PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([EWSocial class])];
    [query whereKey:EWSocialAttributes.facebookID containedIn:facebookIDs];
	NSArray *friendsFbIDs = [[EWPerson me] valueForKeyPath:[NSString stringWithFormat:@"%@.%@.%@", EWPersonRelationships.friends, EWPersonRelationships.socialGraph, EWSocialAttributes.facebookID]];
	if (friendsFbIDs.count) {
		[query whereKey:EWSocialAttributes.facebookID notContainedIn:friendsFbIDs];
        DDLogInfo(@"Exclude friends's facebookID: %@", facebookIDs);
	}
	[query includeKey:EWSocialRelationships.owner];
    [query setLimit:50];
    [EWSync findParseObjectInBackgroundWithQuery:query completion:^(NSArray *objects, NSError *error) {
        DDLogDebug(@"===> Found %ld new facebook friends%@", objects.count, [objects valueForKey:EWPersonAttributes.firstName]);
        NSMutableArray *resultPeople = [NSMutableArray new];
        EWSocial *sg = [EWPerson mySocialGraph];
        for (PFObject *socialPO in objects) {
			PFUser *owner = socialPO[EWSocialRelationships.owner];
			if (!owner) {
				[socialPO fetch:&error];
				owner = socialPO[EWSocialRelationships.owner];
			}
			EWPerson *person = (EWPerson *)[owner managedObjectInContext:mainContext];
            [resultPeople addObject:person];
            
            //add facebook ID to social
            if (![sg.facebookRelatedUsers containsObject:socialPO[EWSocialAttributes.facebookID]]) {
                [sg.facebookRelatedUsers addObject:socialPO[EWSocialAttributes.facebookID]];
            }
        }
        if (block) {
            block(resultPeople.copy, error);
        }
        
        //save my social
        sg.facebookUpdated = [NSDate date];
        [sg save];
    }];
}

- (NSURL *)getFacebookProfilePictureURLWithID:(NSString *)fid {
    NSString *imageUrl = [NSString stringWithFormat:@"http://graph.facebook.com/v2.2/%@/picture?type=large", fid];
    return [NSURL URLWithString:imageUrl];
}
@end
