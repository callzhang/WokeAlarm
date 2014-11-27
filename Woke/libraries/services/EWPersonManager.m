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
#import "EWUserManager.h"
#import "EWNotificationManager.h"
#import "EWNotification.h"
#import "EWCachedInfoManager.h"


@implementation EWPersonManager
@synthesize wakeeList = _wakeeList;
@synthesize isFetchingEveryone = _isFetchingEveryone;

+(EWPersonManager *)sharedInstance{
    static EWPersonManager *sharedPersonStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPersonStore_ = [[EWPersonManager alloc] init];
        //listern to user log in events
        [[NSNotificationCenter defaultCenter] addObserver:sharedPersonStore_ selector:@selector(userLoggedIn:) name:kPersonLoggedIn object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:sharedPersonStore_ selector:@selector(userLoggedOut:) name:kPersonLoggedOut object:nil];
    });
    
    return sharedPersonStore_;
}

#pragma mark - ME
//Current User MO at background thread
- (void)setCurrentUser:(EWPerson *)user{
    [EWPerson me] = user;
    [[EWPerson me] addObserver:self forKeyPath:@"score" options:NSKeyValueObservingOptionNew context:nil];
    [[EWPerson me] addObserver:self forKeyPath:@"lastLocation" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - CREATE USER
-(EWPerson *)getPersonByServerID:(NSString *)ID{
    NSParameterAssert([NSThread isMainThread]);
    if(!ID) return nil;
    EWPerson *person = (EWPerson *)[EWSync findObjectWithClass:@"EWPerson" withID:ID];
    
    return person;
}

#pragma mark - Everyone server code

- (BOOL)isFetchingEveryone{
    @synchronized(self){
        return _isFetchingEveryone;
    }
}

- (void)setIsFetchingEveryone:(BOOL)isFetchingEveryone{
    @synchronized(self){
        _isFetchingEveryone = isFetchingEveryone;
    }
}

- (EWPerson *)nextWakee{
    if (_wakeeList.count == 0) {
        //need to fetch everyone first
        [self wakeeList];
    }
    EWPerson *next = _wakeeList.firstObject;
    [_wakeeList removeObjectAtIndex:_wakeeList.count-1];
    
    //get extra if near empty
    if (_wakeeList.count < 3) {
        [self getWakeesInBackgroundWithCompletion:^{
            //
        }];
    }
    return next;
}

- (NSArray *)wakeeList{
    NSParameterAssert([NSThread isMainThread]);
    
    //fetch from sever
    NSArray *allWakees = [self getWakeesInContext:mainContext];
    
    [_wakeeList addObjectsFromArray:allWakees];
    return _wakeeList;
    
}

- (void)getWakeesInBackgroundWithCompletion:(void (^)(void))block{
    NSParameterAssert([NSThread isMainThread]);
    __block NSArray *wakees;
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        wakees = [self getWakeesInContext:localContext];
    }completion:^(BOOL success, NSError *error) {
        for (EWPerson *localWakee in wakees) {
            EWPerson *person = (EWPerson *)[localWakee MR_inContext:[NSManagedObjectContext MR_defaultContext]];
            if (person) {
                
                [_wakeeList addObject:person];
            }
        }
        
        if (block) {
            block();
        }
    }];
}

- (NSArray *)getWakeesInContext:(NSManagedObjectContext *)context{
    
    //cache
    if (self.isFetchingEveryone) {
        return nil;
    }
    self.isFetchingEveryone = YES;
    //_timeEveryoneChecked = [NSDate date];
    
    
    NSMutableArray *allPerson = [NSMutableArray new];
    
    EWPerson *localMe = [[EWPerson me] MR_inContext:context];
    NSString *parseObjectId = [localMe valueForKey:kParseObjectID];
    NSError *error;
    
    //check my location
    if (!localMe.lastLocation) {
        //get a fake coordinate
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:0 longitude:0];
        localMe.lastLocation = loc;
        
    }
    
    NSArray *list = [PFCloud callFunction:@"getRelevantUsers"
                           withParameters:@{@"objectId": parseObjectId,
                                            @"topk" : numberOfRelevantUsers,
                                            @"radius" : radiusOfRelevantUsers,
                                            @"location": @{@"latitude": @([EWPerson me].lastLocation.coordinate.latitude),
                                                           @"longitude": @([EWPerson me].lastLocation.coordinate.longitude)}}
                                    error:&error];
    
    if (error && list.count == 0) {
        DDLogError(@"*** Failed to get relavent user list: %@", error.description);
        //get cached person
        error = nil;
        self.isFetchingEveryone = NO;
        return nil;
    }
    
    //fetch
    error = nil;
    PFQuery *query = [PFUser query];
    [query whereKey:kParseObjectID containedIn:list];
    //[query includeKey:@"friends"];
    NSArray *users = [EWSync findServerObjectWithQuery:query error:&error];
    
    if (error) {
        NSLog(@"*** Failed to fetch everyone: %@", error);
        self.isFetchingEveryone = NO;
        return nil;
    }
    
    //change the returned people's score;
    for (PFUser *user in users) {
        EWPerson *person = (EWPerson *)[user managedObjectInContext:context];
        
        //remove skipped user
        NSString *skippedStatement = [EWSession sharedSession].skippedWakees[user.objectId];
        if (skippedStatement) {
            if ([skippedStatement isEqualToString:person.statement]) {
                DDLogInfo(@"Same statement for person %@ (%@) skipped", person.name, person.statement);
                continue;
            }
        }
        [allPerson addObject:person];
    }
    
    //batch save to local
    [EWSync saveAllToLocal:allPerson];
    
    //still need to save me
    //localMe.score = @100;
    
    NSLog(@"Received everyone list: %@", [allPerson valueForKey:@"name"]);
    self.isFetchingEveryone = NO;
    
    return allPerson;
}


- (EWPerson *)anyone{
    
    NSInteger i = arc4random_uniform((uint16_t)self.wakeeList.count);
    EWPerson *one = self.wakeeList[i];
    return one;
}



#pragma mark - Notification
//TODO: [ZITAO] move to account manager.
- (void)userLoggedIn:(NSNotification *)notif{
    EWPerson *user = notif.object;
    if (![[EWPerson me] isEqual:user]) {
        self.currentUser = user;
    }
    
}

- (void)userLoggedOut:(NSNotification *)notif{
    self.currentUser = nil;
}




@end
