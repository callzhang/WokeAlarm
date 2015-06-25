//
//  EWPerson(Woke).m
//  Woke
//
//  Created by Lei Zhang on 12/25/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWPerson+Woke.h"
#import "EWAlarmManager.h"
#import "EWActivityManager.h"
#import "EWMediaManager.h"
#import "EWSocialManager.h"
#import "EWAlarm.h"
#import "EWAccountManager.h"
#import "EWNotificationManager.h"
#import "EWCachedInfoManager.h"
#import "EWNotification.h"
#import "NSArray+BlocksKit.h"
#import "EWActivity.h"
#import "EWFriendRequest.h"

NSString * const kFriendshipStatusChanged = @"friendship_status_changed";

@implementation EWPerson(Woke)

#pragma mark - ME
+ (EWPerson *)me{
    if (![NSThread isMainThread]) {
        DDLogWarn(@"Me called on background thread, use [EWPerson meInContext:] instead!");
    }
    return [EWSession sharedSession].currentUser;
}

+ (EWPerson *)meInContext:(NSManagedObjectContext *)context{
    return [[EWSession sharedSession].currentUser MR_inContext:context];
}

- (BOOL)isMe {
    if (!self.serverID) {
        DDLogError(@"Person missing server ID");
        return NO;
    }
    return [self.objectId isEqualToString:[PFUser currentUser].objectId];
}

- (NSString *)name{
    return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}

- (void)updateStatus:(NSString *)status completion:(ErrorBlock)completion {
    [[[self class] myAlarms] enumerateObjectsUsingBlock:^(EWAlarm *obj, NSUInteger idx, BOOL *stop) {
        obj.statement = status;
    }];
    
    [EWPerson me].statement = status;
    
    [[EWPerson me] updateToServerWithCompletion:^(EWServerObject *MO_on_main_thread, NSError *error) {
        completion(error);
    }];
}



- (NSArray *)unreadMedias{
    NSMutableArray *unread = self.receivedMedias.allObjects.mutableCopy;
    for (EWActivity *activity in self.activities) {
        [unread removeObjectsInArray:activity.medias];
    }
    
    //filter out future targeted medias
    NSArray *unreadMediasForToday = [unread bk_select:^BOOL(EWMedia *obj) {
        if (!obj.targetDate) {
            return YES;
        }else if ([obj.targetDate timeIntervalSinceDate:[EWPerson myCurrentAlarmActivity].time.nextOccurTime] < 0){
            return YES;
        }
        return NO;
    }];
    
    //sort by priority and created date
    unreadMediasForToday = [unreadMediasForToday sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWMediaAttributes.priority ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
    return unreadMediasForToday;
}

#pragma mark - My Stuffs

+ (NSArray *)myActivities {
    EWAssertMainThread
    return [[EWActivityManager sharedManager] activitiesForPerson:[EWPerson me]];
}

+ (EWActivity *)myCurrentAlarmActivity{
    EWAssertMainThread
    EWActivity *activity = [[EWActivityManager sharedManager] currentActivityForPerson:[EWPerson me]];
    return activity;
}

+ (NSArray *)myUnreadNotifications {
    EWAssertMainThread
    NSArray *notifications = [self myNotifications];
    NSArray *unread = [notifications filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed == nil"]];
    return unread;
}

+ (NSArray *)myNotifications {
    EWAssertMainThread
    return [[EWNotificationManager shared] notificationsForPerson:[EWPerson me]];
}

+ (NSArray *)myAlarms {
    EWAssertMainThread
    return [[EWAlarmManager sharedInstance] alarmsForPerson:[EWPerson me]];
}

+ (EWAlarm *)myCurrentAlarm {
    EWAssertMainThread
    EWAlarm *next = [[EWAlarmManager sharedInstance] currentAlarmForPerson:[self me]];
//    NSAssert(next, @"current alarm can't be nil");
    return next;
}


+ (NSArray *)myUnreadMedias{
    EWAssertMainThread
    return [EWPerson me].unreadMedias;
}

+ (NSArray *)myFriends{
    EWAssertMainThread
    return [EWPerson me].friends.allObjects;
}

+ (EWSocial *)mySocialGraph{
    EWAssertMainThread
    if ([EWPerson me].socialGraph) {
        return [EWPerson me].socialGraph;
    }
    
    EWSocial *social = [EWSocial newSocialForPerson:[EWPerson me]];
    NSParameterAssert([EWPerson me].socialGraph);
    return social;
}

#pragma mark - Helper methods
- (EWFriendshipStatus)friendshipStatus{
    NSManagedObjectContext *context = self.managedObjectContext;
    EWPerson *me = [EWPerson meInContext:context];
    if ([me.friends containsObject:self]) {
        return EWFriendshipStatusFriended;
    }
    else{
        EWFriendRequest *requestSent = [EWFriendRequest MR_findFirstByAttribute:EWFriendRequestRelationships.receiver withValue:self inContext:context];
        if (requestSent) {
            if ([requestSent.status isEqualToString:EWFriendshipRequestPending]) {
                return EWFriendshipStatusSent;
            }else if ([requestSent.status isEqualToString:EWFriendshipRequestDenied]){
                return EWFriendshipStatusDenied;
            }else if ([requestSent.status isEqualToString:EWFriendshipRequestFriended]) {
                DDLogError(@"Friended on request but not in my friends relation");
                [me addFriendsObject:self];
                [me save];
                return EWFriendshipStatusFriended;
            }
        }
        
        EWFriendRequest *requestReceived = [EWFriendRequest MR_findFirstByAttribute:EWFriendRequestRelationships.sender withValue:self inContext:context];
        if (requestReceived) {
            if ([requestReceived.status isEqualToString:EWFriendshipRequestPending]) {
                return EWFriendshipStatusReceived;
            }else if ([requestReceived.status isEqualToString:EWFriendshipRequestDenied]){
                return EWFriendshipStatusNone;
            }else if ([requestReceived.status isEqualToString:EWFriendshipRequestFriended]) {
                DDLogError(@"Friended on request but not in my friends relation");
                [me addFriendsObject:self];
                [me save];
                return EWFriendshipStatusFriended;
            }
        }
    }
    return EWFriendshipStatusNone;
}


- (float)distance{
    if (self.location) {
        CLLocation *loc0 = [EWPerson me].location;
        CLLocation *loc1 = self.location;
        return [loc0 distanceFromLocation:loc1]/1000;
    }
    return -1;
}

- (NSString *)distanceString{
    float d = self.distance;
    if (d >= 0) {
        return [NSString stringWithFormat:@"%.0f km", d];
    }
    return @"Unknown location";
}

@end

