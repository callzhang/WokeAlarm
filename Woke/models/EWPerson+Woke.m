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
    return [self.objectId isEqualToString:[PFUser currentUser].objectId];
}

- (NSString *)name{
    return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}

- (void)updateStatus:(NSString *)status completion:(void (^)(NSError *))completion {
    [[[self class] myAlarms] enumerateObjectsUsingBlock:^(EWAlarm *obj, NSUInteger idx, BOOL *stop) {
        obj.statement = status;
    }];
    
    [EWPerson me].statement = status;
    
    [EWSync saveWithCompletion:^{
        completion(nil);
    }];
}

#pragma mark - My Stuffs

+ (NSArray *)myActivities {
    EWAssertMainThread
    return [[EWActivityManager sharedManager] activitiesForPerson:[EWPerson me]];
}

+ (NSArray *)myAlarmActivities{
    EWAssertMainThread
    NSArray *activities = [self myActivities];
    NSArray *alarmActivities = [activities bk_select:^BOOL(EWActivity *obj) {
        return [obj.type isEqualToString:EWActivityTypeAlarm] ? YES : NO;
    }];
    return alarmActivities;
}

+ (EWActivity *)myCurrentAlarmActivity{
    EWAssertMainThread
    EWActivity *activity = [[EWActivityManager sharedManager] currentAlarmActivityForPerson:[EWPerson me]];
    return activity;
}

+ (NSArray *)myUnreadNotifications {
    //TODO: move to notification manager
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
    return next;
}


+ (NSArray *)myUnreadMedias{
    EWAssertMainThread
    return [[EWMediaManager sharedInstance] unreadMediasForPerson:[EWPerson me]];
}

+ (NSArray *)myFriends{
    EWAssertMainThread
    return [EWPerson me].friends.allObjects;
}

+ (EWSocial *)mySocialGraph{
    EWAssertMainThread
    return [[EWSocialManager sharedInstance] socialGraphForPerson:[EWPerson me]];
}

#pragma mark - Helper methods


-(BOOL)isFriend {
    BOOL myFriend = self.friendPending;
    BOOL friended = self.friendWaiting;
    
    if (myFriend && friended) {
        return YES;
    }
    return NO;
}

//request pending
- (BOOL)friendPending {
    return [[EWPerson me].cachedInfo[kCachedFriends] containsObject:self.objectId];
}

//wait for friend acceptance
- (BOOL)friendWaiting {
    return [self.cachedInfo[kCachedFriends] containsObject:[EWPerson me].objectId];
}


- (void)requestFriend:(EWPerson *)person{
    //[self addFriendsObject:person];
    //[self updateMyCachedFriends];
    [[EWNotificationManager shared] sendFriendRequestNotificationToUser:person];
    
    [self save];
}

- (void)acceptFriend:(EWPerson *)person{
    [self addFriendsObject:person];
    //[self updateMyCachedFriends];
    [[EWNotificationManager shared] sendFriendAcceptNotificationToUser:person];
    
    [self save];
}

- (void)unfriend:(EWPerson *)person{
    [self removeFriendsObject:person];
    //[self updateMyCachedFriends];
    [self save];
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

