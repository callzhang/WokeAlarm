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


- (BOOL)hasAddressBookAccess {
    return [APAddressBook access] == APAddressBookAccessGranted;
}

- (void)testFindWithUsersCompletion:(void (^)(NSArray *users))completion {
    [self loadAddressBookCompletion:^(NSArray *contacts, NSError *error) {
        NSArray *emails = [contacts bk_map:^id(APContact *obj) {
            return obj.emails;
        }];
        
        NSMutableArray *allEmails = [NSMutableArray array];
        for (NSArray *obj in emails) {
            [allEmails addObjectsFromArray:obj];
        }
        
        [self getUsersFromParse:allEmails completion:^(NSArray *contacts2, NSError *error2) {
            DDLogInfo(@"contacts:%@", contacts);
            completion(contacts);
        }];
    }];
}

- (void)loadAddressBookCompletion:(void (^)(NSArray *contacts, NSError *error))completion {
    [self.addressBook loadContactsOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSArray *contacts, NSError *error) {
        DDLogInfo(@"got contacts: %@", contacts);
        NSArray *mapContacts = [contacts bk_map:^id(APContact *obj) {
            NSDictionary *contact = @{
                                      @"firstName": obj.firstName,
                                      @"middleName": obj.middleName,
                                      @"lastName": obj.lastName,
                                      @"emails": obj.emails,
                                      @"recordID": obj.recordID,
                                      @"socialProfiles": obj.socialProfiles,
                                      @"phones": obj.phones,
                                      @"phonesWithLabels": obj.phonesWithLabels
                                      };
            
            return contact;
        }];
        
        //FIXME: set address book friends to person object?
        [EWPerson mySocialGraph].addressBookFriends = mapContacts;
        
        [EWSync save];
        
        if (completion) {
            completion(contacts, error);
        }
    }];
}

- (void)getUsersFromParse:(NSArray *)emails completion:(void (^)(NSArray *contacts, NSError *error))completion {
    [PFCloud callFunctionInBackground:@"findUsersWithEmails" withParameters:@{@"emails": emails} block:^(id object, NSError *error) {
        if (completion) {
            completion(object, error);
        }
    }];
}

@end
