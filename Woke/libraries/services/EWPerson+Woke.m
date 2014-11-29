//
//  EWPerson(Woke).m
//  Woke
//
//  Created by Lei Zhang on 11/28/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWPerson+Woke.h"
#import "EWPersonManager.h"
#import "EWAlarm.h"
#import "EWNotificationManager.h"
#import "EWCachedInfoManager.h"
#import "EWAccountManager.h"

@implementation EWPerson(Woke)

#pragma mark - ME
+ (EWPerson *)me{
    NSParameterAssert([NSThread isMainThread]);
    return [EWPerson me];
}


- (BOOL)isMe {
    BOOL isme = NO;
    if ([EWPerson me]) {
        isme = [self.username isEqualToString:[EWPerson me].username];
    }
    return isme;
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
            [localMe refreshRelatedWithCompletion:^{
                
                [EWPerson updateMyCachedFriends];
                [EWAccountManager updateFacebookInfo];
            }];
            //TODO: we need a better sync method
            //1. query for medias
            
            
            //2. check
        }];
        
        
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:kLastCheckedMe];
    }
}


#pragma mark - My Stuffs
+ (NSArray *)myActivities {
    NSArray *activities = [EWPerson me].activities.allObjects;
    return [activities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.updatedAt ascending:NO]]];
}

+ (NSArray *)myUnreadNotifications {
    NSArray *notifications = [self myNotifications];
    NSArray *unread = [notifications filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed == nil"]];
    return unread;
}

+ (NSArray *)myNotifications {
    NSArray *notifications = [[EWPerson me].notifications allObjects];
    NSSortDescriptor *sortCompelet = [NSSortDescriptor sortDescriptorWithKey:@"completed" ascending:NO];
    NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO];
    NSSortDescriptor *sortImportance = [NSSortDescriptor sortDescriptorWithKey:@"importance" ascending:NO];
    notifications = [notifications sortedArrayUsingDescriptors:@[sortCompelet,sortImportance, sortDate]];
    return notifications;
}

+ (NSArray *)myAlarms {
    NSParameterAssert([NSThread isMainThread]);
    return [self alarmsForUser:[EWPerson me]];
}

+ (EWAlarm *)myNextAlarm {
    float interval = CGFLOAT_MAX;
    EWAlarm *next;
    for (EWAlarm *alarm in [self myAlarms]) {
        float timeLeft = alarm.time.nextOccurTime.timeIntervalSinceNow;
        if (alarm.state) {
            if (interval == 0 || timeLeft < interval) {
                interval = timeLeft;
                next = alarm;
            }
        }
    }
    return next;
}

+ (NSArray *)myFriends{
    return [EWPerson me].friends.allObjects;
}


+ (NSArray *)alarmsForUser:(EWPerson *)user{
    NSMutableArray *alarms = [[user.alarms allObjects] mutableCopy];
    
    NSComparator alarmComparator = ^NSComparisonResult(id obj1, id obj2) {
        NSInteger wkd1 = [(EWAlarm *)obj1 time].mt_weekdayOfWeek;
        NSInteger wkd2 = [(EWAlarm *)obj2 time].mt_weekdayOfWeek;
        if (wkd1 > wkd2) {
            return NSOrderedDescending;
        }else if (wkd1 < wkd2){
            return NSOrderedAscending;
        }else{
            return NSOrderedSame;
        }
    };
    
    //sort
    NSArray *sortedAlarms = [alarms sortedArrayUsingComparator:alarmComparator];
    
    return sortedAlarms;
}

#pragma mark - Tools
+ (void)updateMeFromFacebook{
    [EWAccountManager updateFacebookInfo];
}
@end
