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
    if (person.socialGraph) {
        return person.socialGraph;
    }
	
    EWSocial *graph = [EWSocial newSocialForPerson:person];
	if (person.isMe) {
        //TODO: update facebook friends
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
    //request for access
    switch ([RHAddressBook authorizationStatus]) {
        case RHAuthorizationStatusNotDetermined:{
            //request authorization
            [self.addressBook requestAuthorizationWithCompletion:^(bool granted, NSError *error) {
                if (granted) {
                    [self findAddressbookUsersFromContactsWithCompletion:completion];
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
    EWSocial *social = [EWPerson mySocialGraph];
    NSArray *contacts = [self.addressBook people];
    NSMutableArray *myContactFriends = social.addressBookFriends ?: [NSMutableArray array];
    for (RHPerson *contact in contacts) {
        for (NSString *email in contact.emails.values) {
            if (![myContactFriends containsObject:email]) {
                [myContactFriends addObject:email];
            }
        }
    };
    social.addressBookFriends = myContactFriends;
    [social save];
    
    //Update email to EWSocial
    
    [self getUsersWithEmails:myContactFriends completion:^(NSArray *people, NSError *error) {
        if (completion) {
            completion(people, error);
        }
    }];
}



#pragma mark - Search user
- (void)searchUserWithPhrase:(NSString *)phrase completion:(ArrayBlock)block{
    phrase = [phrase stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!phrase || phrase.length == 0) {
        block(nil, nil);
        return;
    }
    
    if (phrase.isEmail) {
        DDLogDebug(@"search for email");
        [self getUsersWithEmails:@[phrase] completion:^(NSArray *array, NSError *error) {
            block(array, error);
        }];
    }else{
        DDLogDebug(@"search for name");
        [self getUsersWithName:phrase completion:^(NSArray *array, NSError *error) {
            block(array, error);
        }];
    }
}

- (void)getUsersWithEmails:(NSArray *)emails completion:(ArrayBlock)completion {
    PFQuery *emailQ = [PFUser query];
    [emailQ whereKey:EWPersonAttributes.email containedIn:emails];
    [emailQ findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
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

- (void)getUsersWithName:(NSString *)name completion:(ArrayBlock)completion {
    NSString *name_ = [name stringByReplacingOccurrencesOfString:@"," withString:@" "];
    NSArray *subNames = [name_ componentsSeparatedByString:@" "];
    PFQuery *query;
    for (NSString *str in subNames) {
        PFQuery *q1 = [[PFUser query] whereKey:EWPersonAttributes.firstName equalTo:str];
        PFQuery *q2 = [[PFUser query] whereKey:EWPersonAttributes.lastName equalTo:str];
        query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:q1, q2, query, nil]];
    }
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
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
- (void)searchForFacebookFriendsWithCompletion:(ArrayBlock)block{
    //get list of fb id
    EWSocial *social = [EWPerson mySocialGraph];
    NSArray *facebookIDs = social.facebookFriends;
    if (facebookIDs.count == 0) {
        block(nil, nil);
        return;
    }
    PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([EWSocial class])];
    [query whereKey:EWSocialAttributes.facebookID containedIn:facebookIDs];
	NSArray *friendsFbIDs = [[EWPerson me] valueForKeyPath:[NSString stringWithFormat:@"%@.%@.%@", EWPersonRelationships.friends, EWPersonRelationships.socialGraph, EWSocialAttributes.facebookID]];
	if (friendsFbIDs.count) {
		[query whereKey:EWSocialAttributes.facebookID notContainedIn:friendsFbIDs];
	}
	[query includeKey:EWSocialRelationships.owner];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        DDLogDebug(@"===> Found %ld new facebook friends%@", objects.count, [objects valueForKey:EWPersonAttributes.firstName]);
        NSMutableArray *resultPeople = [NSMutableArray new];
        for (PFObject *socialPO in objects) {
			PFUser *owner = socialPO[EWSocialRelationships.owner];
			if (!owner) {
				[socialPO fetch:&error];
				owner = socialPO[EWSocialRelationships.owner];
			}
			EWPerson *person = (EWPerson *)[owner managedObjectInContext:mainContext];
            [resultPeople addObject:person];
        }
        if (block) {
            block(resultPeople, error);
        }
    }];
}
@end
