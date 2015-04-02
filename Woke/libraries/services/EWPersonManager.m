//
//  EWPersonStore.m
//  EarlyWorm
//
//  Created by Lei on 8/16/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWPersonManager.h"
#import "EWMediaManager.h"
#import "EWMedia.h"
#import "EWPerson.h"
#import "EWUtil.h"
#import "EWAlarmManager.h"
#import "NSDate+Extend.h"
#import "EWStartUpSequence.h"

#import "EWNotificationManager.h"
#import "EWNotification.h"
#import "EWCachedInfoManager.h"
//#import "FBKVOController.h"
#import <KVOController/FBKVOController.h>
#import "EWBlockTypes.h"
#import "EWUIUtil.h"
#import "EWFriendRequest.h"
#import "EWErrorManager.h"
#import "FBKVOController.h"

@interface EWPersonManager()
@property (nonatomic, strong) NSMutableArray *wakeeListChangeBlocks;
@end

@implementation EWPersonManager
@synthesize wakeeList = _wakeeList;
@synthesize isFetchingWakees = _isFetchingWakees;

GCD_SYNTHESIZE_SINGLETON_FOR_CLASS(EWPersonManager)

- (EWPersonManager *)init{
    if (self = [super init]) {
        _wakeeList = [NSMutableArray new];
        _wakeeListChangeBlocks = [NSMutableArray new];
    }
    return self;
}

#pragma mark - CREATE USER
-(EWPerson *)getPersonByServerID:(NSString *)ID error:(NSError *__autoreleasing *)error{
    EWAssertMainThread
    if(!ID) return nil;
    EWPerson *person = (EWPerson *)[EWSync findObjectWithClass:NSStringFromClass([EWPerson class]) withID:ID error:error];
    
    return person;
}

#pragma mark - Everyone server code

- (BOOL)isFetchingWakees{
    @synchronized(self){
        return _isFetchingWakees;
    }
}

- (void)setIsFetchingWakees:(BOOL)isFetchingEveryone{
    @synchronized(self){
        _isFetchingWakees = isFetchingEveryone;
    }
}

- (void)nextWakeeWithCompletion:(void (^)(EWPerson *person))block{
    if (!_wakeeList || _wakeeList.count == 0) {
        //need to fetch everyone first
        if (!self.isFetchingWakees) {
            [self getWakeesInBackgroundWithCompletion:^{
                //return next
                if (block) {
                    block(_wakeeList.firstObject);
                    [_wakeeList removeObject:_wakeeList.firstObject];
                }
            }];
        }
    }
    else{
        if (block) {
            block(_wakeeList.firstObject);
            [_wakeeList removeObject:_wakeeList.firstObject];
        }
        
        //get extra if near empty
        if (_wakeeList.count < 3) {
            [self getWakeesInBackgroundWithCompletion:^{
                //
            }];
        }
    }
    
}

//- (NSArray *)getWakeeList{
//    EWAssertMainThread
//    //check
//    if (self.isFetchingWakees) {
//        return nil;
//    }
//    //fetch from sever
//    NSArray *allWakees = [self getWakeesInContext:mainContext];
//    
//    [_wakeeList addObjectsFromArray:allWakees];
//    return _wakeeList;
//    
//}

- (void)getWakeesInBackgroundWithCompletion:(VoidBlock)block{
    EWAssertMainThread
    //add finish block to the queue
    if (block) {
        [_wakeeListChangeBlocks addObject:block];
    }
    
	//check my location
	if (![EWPerson me].location) {
		//get a fake coordinate
		DDLogWarn(@"Location unknown, waiting for location!");
		[[NSNotificationCenter defaultCenter] addObserverForName:kUserLocationUpdated object:nil queue:nil usingBlock:^(NSNotification *note) {
			if ([EWPerson me].location) {
				[[NSNotificationCenter defaultCenter] removeObserver:self name:kUserLocationUpdated object:nil];
				[self getWakeesInBackgroundWithCompletion:block];
			}
		}];
		return;
	}
	
    __block NSArray *wakees;
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        
		NSError *error;
        wakees = [self getWakeesInContext:localContext error:&error];
		if (error) DDLogError(@"Failed to get wakees: %@", error);
		
    } completion:^(BOOL success, NSError *error) {
		
		if (error) DDLogError(@"Failed to save wakees: %@", error);
        for (EWPerson *localWakee in wakees) {
            EWPerson *person = (EWPerson *)[localWakee MR_inContext:mainContext];
            if (person) {
                [self.wakeeList addObject:person];
            }
        }
        
        //execute finishing block
        for (VoidBlock b in _wakeeListChangeBlocks) {
            b();
        }
        [_wakeeListChangeBlocks removeAllObjects];
    }];
}

//worker
- (NSArray *)getWakeesInContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error{
	NoneErrorCreate(error);
	//check
	if (self.isFetchingWakees) {
		DDLogWarn(@"Already fetching wakees");
		return nil;
	}
	
    self.isFetchingWakees = YES;
    //_timeEveryoneChecked = [NSDate date];
    
    NSMutableArray *allPerson = [NSMutableArray new];
    EWPerson *localMe = [EWPerson meInContext:context];
    
    //check my location
    if (!localMe.location) {
        //get a fake coordinate
		DDLogError(@"Location unknown, abord getting wakees!");
		return nil;
    }
    
    NSArray *list = [PFCloud callFunction:@"getRelevantUsers"
                           withParameters:@{@"objectId": localMe.objectId,
                                            @"topk" : numberOfRelevantUsers,
                                            @"radius" : radiusOfRelevantUsers,
                                            @"location": @{@"latitude": @(localMe.location.coordinate.latitude),
                                                           @"longitude": @(localMe.location.coordinate.longitude)}}
                                    error:error];
    
    if (error && list.count == 0) {
        DDLogError(@"*** Failed to get relavent user list: %@", [*error description]);
        //get cached person
        error = nil;
        self.isFetchingWakees = NO;
        return nil;
    }
    
    //fetch
    PFQuery *query = [PFUser query];
    [query whereKey:kParseObjectID containedIn:list];
    //[query includeKey:@"friends"];
    NSArray *people = [EWSync findObjectFromServerWithQuery:query inContext:context error:error];
    
    if (*error) {
        DDLogError(@"*** Failed to fetch wakees: %@", *error);
        self.isFetchingWakees = NO;
        return nil;
    }
	
    for (EWPerson *person in people) {
        
        //remove skipped user if marked skip and the statement is the same.
        NSString *skippedStatement = [EWSession sharedSession].skippedWakees[person.serverID];
        if (skippedStatement) {
            if ([skippedStatement isEqualToString:person.statement]) {
                DDLogInfo(@"Same statement for person %@ (%@) skipped", person.name, person.statement);
                continue;
            }
        }
        [allPerson addObject:person];
    }
    
    //still need to save me
    //localMe.score = @100;
    
    DDLogVerbose(@"Received everyone list: %@", [allPerson valueForKey:@"name"]);
    self.isFetchingWakees = NO;
    
    return allPerson;
}


- (EWPerson *)anyone{
    
    NSInteger i = arc4random_uniform((uint16_t)self.wakeeList.count);
    EWPerson *one = self.wakeeList[i];
    return one;
}



#pragma mark - Friendship

- (void)requestFriend:(EWPerson *)person completion:(void (^)(EWFriendshipStatus status, NSError *error))completion{
    EWAssertMainThread
	[EWUIUtil showWatingHUB];
    [self sendFriendRequestToPerson:person completion:^(EWFriendRequest *request, NSError *error) {
        if (request) {
            [[EWPerson me] addFriendshipRequestSentObject:request];
            [[EWPerson me] saveToLocal];
            if (completion) {
                if([request.status isEqualToString:EWFriendshipRequestPending]) {
                    completion(EWFriendshipStatusSent, error);
                } else if ([request.status isEqualToString:EWFriendshipRequestFriended]) {
                    completion(EWFriendshipStatusFriended, error);
                } else if ([request.status isEqualToString:EWFriendshipRequestDenied]) {
                    completion(EWFriendshipStatusDenied, error);
                }
            }
        }
        else {
			[EWUIUtil showFailureHUBWithString:@"Failed"];
			completion(EWFriendshipStatusUnknown, error);
        }
    }];
}

- (void)acceptFriend:(EWPerson *)person completion:(void (^)(EWFriendshipStatus status, NSError *error))completion{
    
    EWAssertMainThread
	
	[EWUIUtil showWatingHUB];
	
    [self sendFriendAcceptToPerson:person completion:^(EWFriendRequest *request, NSError *error) {
        if (request) {
            [[EWPerson me] addFriendsObject:person];
            [[EWPerson me] saveToLocal];
            if (completion) {
                if([request.status isEqualToString:EWFriendshipRequestPending]) {
                    completion(EWFriendshipStatusReceived, error);
                } else if ([request.status isEqualToString:EWFriendshipRequestFriended]) {
                    completion(EWFriendshipStatusFriended, error);
                } else if ([request.status isEqualToString:EWFriendshipRequestDenied]) {
                    completion(EWFriendshipStatusNone, error);
                }
            }
        }
        else {
            [EWUIUtil showFailureHUBWithString:@"Failed"];
            completion(EWFriendshipStatusUnknown, error);
        }
    }];
    
    
}

- (void)unfriend:(EWPerson *)person completion:(BoolErrorBlock)completion{
    EWAssertMainThread
    [self sendUnfriendStatusToPerson:person completion:^(BOOL success, NSError *error) {
        if (success) {
            [[EWPerson me] removeFriendsObject:person];
            [[EWPerson me] saveToLocal];
        }
        completion(success, error);
    }];
}

- (void)sendFriendRequestToPerson:(EWPerson *)person completion:(void (^)(EWFriendRequest *request, NSError *))block {
    if (![EWSync isReachable]) {
        NSError *error = [EWErrorManager noInternetConnectError];
        block(nil, error);
        return;
    }
    /*
     call the cloud code
     server create a friendRequest and a notification object
     request.sender = me
     request.receiver = person
     request.status = EWFriendshipStatusPending
     
     notification.type = kNotificationTypeFriendRequest
     notification.sender = me.objectId
     notification.owner = the recerver AND person.notification add this notification
     
     create push:
     title: Friendship request
     body: /name/ is requesting your premission to become your friend.
     userInfo: {User:user.objectId, Type: kNotificationTypeFriendRequest}
     
     */
    [PFCloud callFunctionInBackground:@"sendFriendshipRequestToUser"
                       withParameters:@{@"sender": [EWPerson me].serverID, @"receiver": person.serverID}
                                block:^(PFObject *object, NSError *error)
     {
         if (!object) {
             DDLogError(@"Failed sending friendship request: %@", error.description);
             if (block) {
                 block(nil, error);
             }
         }else{
             DDLogInfo(@"Cloud code sendFriendRequestToUser successful");
             EWFriendRequest *request = (EWFriendRequest *)[object managedObjectInContext:mainContext option:EWSyncOptionUpdateRelation completion:NULL];
             NSAssert([[EWPerson me].friendshipRequestSent containsObject:request], @"Request not in my relation");
             block(request, error);
         }
     }];
}

- (void)sendFriendAcceptToPerson:(EWPerson *)person completion:(void (^)(EWFriendRequest *request, NSError *error))block {
    if (![EWSync isReachable]) {
        NSError *error = [EWErrorManager noInternetConnectError];
        block(nil, error);
        return;
    }
    /*
     call the cloud code
     server updates the request status to friended
     
     server create a notification object
     notification.type = kNotificationTypeFriendAccepted
     notification.sender = me.objectId
     notification.owner = the recerver AND person.notification add this notification
     
     create push:
     title: Friendship accepted
     body: /name/ has approved your friendship request. Now send her/him a voice greeting!
     userInfo: {User:user.objectId, Type: kNotificationTypeFriendAccepted}
     */
    [PFCloud callFunctionInBackground:@"sendFriendshipAcceptanceToUser"
                       withParameters:@{@"sender": [EWPerson me].objectId, @"receiver": person.objectId}
                                block:^(PFObject *object, NSError *error)
     {
         if (!object) {
             DDLogError(@"Failed sending friendship acceptance: %@", error.description);
             if (block) {
                 block(nil, error);
             }
         }else{
             DDLogInfo(@"Cloud code sendFriendRequestToUser successful");
             EWFriendRequest *request = (EWFriendRequest *)[object managedObjectInContext:mainContext option:EWSyncOptionUpdateRelation completion:NULL];
             block(request, error);
         }
     }];
}

- (void)sendUnfriendStatusToPerson:(EWPerson *)person completion:(BoolErrorBlock)block{
    [PFCloud callFunctionInBackground:@"sendUnfriendStatusToUser"
                       withParameters:@{@"sender": person.objectId,
                                        @"receiver": [EWPerson me].objectId}
                                block:^(NSNumber *success, NSError *error)
    {
        block(success.boolValue, error);
    }];
}

- (void)testGenerateFriendRequestFrom:(EWPerson *)person completion:(void (^)(EWFriendRequest *request, NSError *error))block{
    [PFCloud callFunctionInBackground:@"sendFriendshipRequestToUser"
                       withParameters:@{@"sender": person.objectId,
                                        @"receiver": [EWPerson me].objectId}
                                block:^(PFObject *object, NSError *error)
     {
         if (!object) {
             DDLogError(@"Failed generating friendship request: %@", error.description);
             if (block) {
                 block(nil, error);
             }
         }else{
             DDLogInfo(@"generateFriendRequestFrom %@ successful", person.name);
             EWFriendRequest *request = (EWFriendRequest *)[object managedObjectInContext:mainContext option:EWSyncOptionUpdateRelation completion:NULL];
             if (block) {
                 block(request, error);
             }
             
         }
     }];
}


@end
