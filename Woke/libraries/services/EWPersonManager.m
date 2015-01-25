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
-(EWPerson *)getPersonByServerID:(NSString *)ID{
    EWAssertMainThread
    if(!ID) return nil;
    EWPerson *person = (EWPerson *)[EWSync findObjectWithClass:NSStringFromClass([EWPerson class]) withID:ID error:nil];
    
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
    
    //check
    if (self.isFetchingWakees) {
        DDLogWarn(@"Already fetching wakees");
        return;
    }
    
    __block NSArray *wakees;
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        wakees = [self getWakeesInContext:localContext];
    } completion:^(BOOL success, NSError *error) {
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

- (NSArray *)getWakeesInContext:(NSManagedObjectContext *)context{
    
    self.isFetchingWakees = YES;
    //_timeEveryoneChecked = [NSDate date];
    
    
    NSMutableArray *allPerson = [NSMutableArray new];
    
    EWPerson *localMe = [EWPerson meInContext:context];
    NSError *error;
    
    //check my location
    if (!localMe.location) {
        //get a fake coordinate
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:0 longitude:0];
        localMe.location = loc;
        
    }
    
    NSArray *list = [PFCloud callFunction:@"getRelevantUsers"
                           withParameters:@{@"objectId": localMe.objectId,
                                            @"topk" : numberOfRelevantUsers,
                                            @"radius" : radiusOfRelevantUsers,
                                            @"location": @{@"latitude": @(localMe.location.coordinate.latitude),
                                                           @"longitude": @(localMe.location.coordinate.longitude)}}
                                    error:&error];
    
    if (error && list.count == 0) {
        DDLogError(@"*** Failed to get relavent user list: %@", error.description);
        //get cached person
        error = nil;
        self.isFetchingWakees = NO;
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
        self.isFetchingWakees = NO;
        return nil;
    }
    
    //change the returned people's score;
    for (PFUser *user in users) {
        EWPerson *person = (EWPerson *)[user managedObjectInContext:context];
        
        //remove skipped user if marked skip and the statement is the same.
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
    
    DDLogVerbose(@"Received everyone list: %@", [allPerson valueForKey:@"name"]);
    self.isFetchingWakees = NO;
    
    return allPerson;
}


- (EWPerson *)anyone{
    
    NSInteger i = arc4random_uniform((uint16_t)self.wakeeList.count);
    EWPerson *one = self.wakeeList[i];
    return one;
}






@end
