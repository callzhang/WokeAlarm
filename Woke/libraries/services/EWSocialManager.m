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

#import "APAddressBook.h"
#import "APContact.h"
#import "NSArray+BlocksKit.h"
#import "EWSocial.h"
#import "FBKVOController.h"

@interface EWSocialManager()
@property (nonatomic, strong) APAddressBook *addressBook;
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


- (APAddressBook *)addressBook {
    if (!_addressBook) {
        _addressBook = [[APAddressBook alloc] init];
    }
    
    return _addressBook;
}

- (EWSocial *)socialGraphForPerson:(EWPerson *)person{
    if (person.socialGraph) {
        return person.socialGraph;
    }
	
    EWSocial *graph = [EWSocial newSocialForPerson:person];
	if (person.isMe) {
		[self loadAddressBookCompletion:^(NSArray *contacts, NSError *error) {
			if (contacts) {
				DDLogInfo(@"Loaded %ld contacts to social graph", contacts.count);
			}else{
				DDLogError(@"Failed to load contacts: %@", error.description);
			}
		}];
	}
    return graph;
}

#pragma mark - Addressbook
- (BOOL)hasAddressBookAccess {
    return [APAddressBook access] == APAddressBookAccessGranted;
}

- (void)findUsersFromContactsWithCompletion:(void (^)(NSArray *users))completion {
    [self loadAddressBookCompletion:^(NSArray *contacts, NSError *error) {
        NSArray *emails = [contacts bk_map:^id(APContact *obj) {
            return obj.emails;
        }];
        
        [self getUsersWithEmails:emails completion:^(NSArray *users, NSError *error2) {
            DDLogDebug(@"Found contacts:%@ with error:%@", contacts, error2);
            completion(contacts);
        }];
    }];
}

- (void)loadAddressBookCompletion:(void (^)(NSArray *contacts, NSError *error))completion {
    
    //FIXME: enable this shit
    
//    [self.addressBook loadContactsOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSArray *contacts, NSError *error) {
//        DDLogInfo(@"got contacts: %@", contacts);
//        NSArray *mapContacts = [contacts bk_map:^id(APContact *obj) {
//            NSDictionary *contact = @{
//                                      @"firstName": obj.firstName,
//                                      @"middleName": obj.middleName,
//                                      @"lastName": obj.lastName,
//                                      @"emails": obj.emails,
//                                      @"recordID": obj.recordID,
//                                      @"socialProfiles": obj.socialProfiles,
//                                      @"phones": obj.phones,
//                                      @"phonesWithLabels": obj.phonesWithLabels
//                                      };
//            
//            return contact;
//        }];
//        
//        //FIXME: set address book friends to person object?
//        [EWPerson mySocialGraph].addressBookFriends = mapContacts;
//        
//        [EWSync save];
    
        if (completion) {
//            completion(contacts, error);
            completion(nil, nil);
        }
//    }];
}

#pragma mark - Search user
- (void)getUsersWithEmails:(NSArray *)emails completion:(void (^)(NSArray *users, NSError *error))completion {
    PFQuery *emailQ = [PFUser query];
    [emailQ whereKey:EWPersonAttributes.email containedIn:emails];
    [emailQ findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        completion(objects, error);
    }];
}

- (void)getUsersWithName:(NSString *)name completion:(void (^)(NSArray *users, NSError *error))completion {
    NSInteger spaceIdx = [name rangeOfString:@" "].location;
    NSInteger spaceInx2 = [name rangeOfString:@", "].location;
    NSString *firstName;
    NSString *lastName;
    PFQuery *firstNameQ = [PFUser query];
    PFQuery *lastNameQ = [PFUser query];
    if (spaceIdx != NSNotFound) {
        firstName = [name substringToIndex:spaceIdx];
        lastName = [name substringFromIndex:spaceIdx+1];
        
        DDLogVerbose(@"Search for first name: %@ AND last name: %@", firstName, lastName);
    }else if(spaceInx2 != NSNotFound){
        firstName = [name substringFromIndex:spaceInx2+2];
        lastName = [name substringToIndex:spaceInx2];
        DDLogVerbose(@"Search for first name: %@ AND last name: %@", firstName, lastName);
    }else{
        firstName = name;
        DDLogVerbose(@"Search for first name: %@ OR last name: %@", firstName, firstName);
    }
    
    PFQuery *query;
    [firstNameQ whereKey:EWPersonAttributes.firstName hasPrefix:firstName];
    if (lastName) {
        [firstNameQ whereKey:EWPersonAttributes.lastName hasPrefix:lastName];
        query = firstNameQ;
    }else{
        [lastNameQ whereKey:EWPersonAttributes.lastName hasPrefix:firstName];
        query = [PFQuery orQueryWithSubqueries:@[firstNameQ, lastNameQ]];
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSMutableArray *persons = [NSMutableArray new];
        for (PFUser *user in objects) {
            EWPerson *person = (EWPerson *)[user managedObjectInContext:mainContext];
            [persons addObject:person];
        }
        if (completion) {
            completion(persons, error);
        }
    }];
    
}

@end
