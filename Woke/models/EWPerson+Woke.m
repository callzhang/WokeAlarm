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

//FIXME: took too long, need to optimize, maybe use one server call.
//check my relation, used for new installation with existing user
+ (void)updateMe{
    NSDate *lastCheckedMe = [[NSUserDefaults standardUserDefaults] valueForKey:kLastCheckedMe];
    BOOL good = [[EWPerson me] validate];
    if (!good || !lastCheckedMe || lastCheckedMe.timeElapsed > kCheckMeInternal) {
        if (!good) {
            DDLogError(@"Failed to validate me, refreshing from server");
        }else if (!lastCheckedMe) {
            DDLogError(@"Didn't find lastCheckedMe date, start to refresh my relation in background");
        }else{
            DDLogError(@"lastCheckedMe date is %@, which exceed the check interval %d, start to refresh my relation in background", lastCheckedMe.date2detailDateString, kCheckMeInternal);
        }
        
        [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
            EWPerson *localMe = [[EWPerson me] MR_inContext:localContext];
            [localMe refreshRelatedWithCompletion:^(NSError *error){
                
                [localMe updateMyCachedFriends];
                [[EWAccountManager shared] updateMyFacebookInfo];
            }];
            //TODO: we need a better sync method
            //1. query for medias
            
            
            //2. check
        }];
        
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:kLastCheckedMe];
    }
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
    return [[EWActivityManager sharedManager] activitiesForPerson:[EWPerson me] inContext:mainContext];
}

+ (NSArray *)myAlarmActivities{
    NSArray *activities = [self myActivities];
    NSArray *alarmActivities = [activities bk_select:^BOOL(EWActivity *obj) {
        return [obj.type isEqualToString:EWActivityTypeAlarm] ? YES : NO;
    }];
    return alarmActivities;
}

+ (EWActivity *)myCurrentAlarmActivity{
    EWActivity *activity = [[EWActivityManager sharedManager] currentAlarmActivityForPerson:[EWPerson me]];
    return activity;
}

+ (NSArray *)myUnreadNotifications {
    NSArray *notifications = [self myNotifications];
    NSArray *unread = [notifications filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed == nil"]];
    return unread;
}

+ (NSArray *)myNotifications {
    NSArray *notifications = [EWPerson me].notifications.allObjects;
    NSSortDescriptor *sortCompelete = [NSSortDescriptor sortDescriptorWithKey:EWNotificationAttributes.completed ascending:NO];
    NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.createdAt ascending:NO];
    NSSortDescriptor *sortImportance = [NSSortDescriptor sortDescriptorWithKey:EWNotificationAttributes.importance ascending:NO];
    notifications = [notifications sortedArrayUsingDescriptors:@[sortDate, sortCompelete, sortImportance]];
    return notifications;
}

+ (NSArray *)myAlarms {
    EWAssertMainThread
    return [[EWAlarmManager sharedInstance] alarmsForPerson:[EWPerson me]];
}

+ (EWAlarm *)myCurrentAlarm {
    EWAlarm *next = [[EWAlarmManager sharedInstance] currentAlarmForPerson:[self me]];
    return next;
}


+ (NSArray *)myUnreadMedias{
    return [[EWMediaManager sharedInstance] unreadMediasForPerson:[EWPerson me]];
}

+ (NSArray *)myFriends{
    return [EWPerson me].friends.allObjects;
}

+ (EWSocial *)mySocialGraph{
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
    [self addFriendsObject:person];
    [self updateMyCachedFriends];
    [EWNotificationManager sendFriendRequestNotificationToUser:person];
    
    [self save];
}

- (void)acceptFriend:(EWPerson *)person{
    [self addFriendsObject:person];
    [self updateMyCachedFriends];
    [EWNotificationManager sendFriendAcceptNotificationToUser:person];
    
    [self save];
}

- (void)unfriend:(EWPerson *)person{
    [self removeFriendsObject:person];
    [self updateMyCachedFriends];
    [self save];
}

- (void)updateMyCachedFriends{
    [[EWCachedInfoManager myManager] updateCachedFriends];
}

//- (void)updateMyFriends {
//    NSArray *friendsCached = self.cachedInfo[kCachedFriends]?:[NSArray new];
//    NSSet *friends = self.friends;
//    BOOL friendsNeedUpdate = self.isMe && friendsCached.count !=self.friends.count;
//    if (!friends || friendsNeedUpdate) {
//        
//        DDLogInfo(@"Friends mismatch, fetch from server");
//        
//        //friend need update
//        PFQuery *q = [PFQuery queryWithClassName:self.serverClassName];
//        [q includeKey:@"friends"];
//        [q whereKey:kParseObjectID equalTo:self.serverID];
//        PFObject *user = [[EWSync findServerObjectWithQuery:q] firstObject];
//        NSArray *friendsPO = user[@"friends"];
//        if (friendsPO.count == 0) return;//prevent 0 friend corrupt data
//        NSMutableSet *friendsMO = [NSMutableSet new];
//        for (PFObject *f in friendsPO) {
//            if ([f isKindOfClass:[NSNull class]]) {
//                continue;
//            }
//            EWPerson *mo = (EWPerson *)[f managedObjectInContext:self.managedObjectContext];
//            [friendsMO addObject:mo];
//        }
//        self.friends = [friendsMO copy];
//        if (self.isMe) {
//            [EWPerson updateMyCachedFriends];
//        }
//    }
//}
@end

