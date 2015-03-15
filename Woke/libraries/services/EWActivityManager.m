//
//  EWActivityManager.m
//  Woke
//
//  Created by Lei Zhang on 10/29/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "EWActivityManager.h"
#import "EWPerson.h"
#import "EWActivity.h"
#import "EWAlarm.h"
#import "NSArray+BlocksKit.h"
#import "EWMedia.h"
#import "EWAlarmManager.h"
#import "EWWakeUpManager.h"
#import "EWNotificationManager.h"

NSString *const EWActivityTypeAlarm = @"alarm";
NSString *const EWActivityTypeFriendship = @"friendship";
NSString *const EWActivityTypeMedia = @"media";

@implementation EWActivityManager

+ (EWActivityManager *)sharedManager{
    static EWActivityManager *manager;
    if (!manager) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            manager = [[EWActivityManager alloc] init];
        });
    }
    return manager;
}

- (NSArray *)activitiesForPerson:(EWPerson *)person{
    NSArray *activities = person.activities.allObjects;
    activities = [activities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.updatedAt ascending:NO]]];
    return activities;
}

- (EWActivity *)currentActivityForPerson:(EWPerson *)person{
    //EWAssertMainThread
    EWAlarm *alarm = [[EWAlarmManager sharedInstance] currentAlarmForPerson:person];
    
    BOOL completed = _currentAlarmActivity.completed && ![EWWakeUpManager shared].skipCheckActivityCompleted;
    BOOL timeMatched = [_currentAlarmActivity.time isEqualToDate: alarm.time.nextOccurTime];
    
    //reset current alarm if any of
    if (!_currentAlarmActivity || !timeMatched || completed) {
        _currentAlarmActivity = [self activityForAlarm:alarm];
        completed = _currentAlarmActivity.completed && ![EWWakeUpManager shared].skipCheckActivityCompleted;
        timeMatched = [_currentAlarmActivity.time isEqualToDate: alarm.time.nextOccurTime];
        NSParameterAssert(!completed && timeMatched);
    }
    
    return _currentAlarmActivity;
}

- (EWActivity *)activityForAlarm:(EWAlarm *)alarm{
    if (!alarm || ![alarm validate]) {
        return nil;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@ AND %K = %@", EWActivityAttributes.alarmID, alarm.serverID, EWActivityRelationships.owner, alarm.owner];
    NSMutableArray *activities = [EWActivity MR_findAllWithPredicate:predicate].mutableCopy;
    [activities sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.createdAt ascending:YES]]];
    while (activities.count >1) {
        EWActivity *activity = activities.firstObject;
        DDLogError(@"Multiple current alarm activities found, please check: \n%@", activity.serverID);
        [activities removeObject:activity];
        [activity remove];
    }
    if (activities.count == 0) {
        EWActivity *activity = [self newActivityForAlarm:alarm];
        [activities addObject:activity];
    }else{
        EWActivity *activity = activities.firstObject;
        if (![activity.time isEqualToDate:alarm.time.nextOccurTime]) {
            DDLogWarn(@"Activity %@ time %@ doesn't not equal to alarm %@ time %@", activity.serverID, activity.time, alarm.serverID, alarm.time);
            activity.time = alarm.time.nextOccurTime;
            [activity save];
        }
    }
    
    return activities.lastObject;
}

- (EWActivity *)newActivityForAlarm:(EWAlarm *)alarm{
    //create new activity
    DDLogDebug(@"Creating new activity for alarm: %@", alarm);
    EWActivity *activity = [EWActivity newActivity];
    activity.owner = alarm.owner;
    activity.type = EWActivityTypeAlarm;
    activity.time = alarm.time.nextOccurTime;
    activity.alarmID = alarm.serverID;
    activity.createdAt = [NSDate date];
    [activity save];
    return activity;
}

- (void)completeAlarmActivity:(EWActivity *)activity{
    NSParameterAssert([activity.type isEqualToString:EWActivityTypeAlarm]);
    if (activity != self.currentAlarmActivity) {
        DDLogError(@"%s The activity passed in is not the current activity", __FUNCTION__);
    }else{
        //add unread medias to current media
        NSArray *played = [EWPerson myUnreadMedias];
        [activity addMediaIDs:[played valueForKey:kParseObjectID]];
        DDLogInfo(@"Added %ld medias to activity %@", (unsigned long)played.count, activity.time.string);
    }
    activity.statement = [EWPerson meInContext:activity.managedObjectContext].statement;
    activity.completed = [NSDate date];
	[[EWNotificationManager shared] deleteNewMediaNotificationForActivity:activity];
    self.currentAlarmActivity = nil;
	[EWPerson me].updatedAt = [NSDate date];
	[activity save];
}

#pragma mark - Delegate
- (BOOL)wakeupManager:(EWWakeUpManager *)manager shouldWakeUpWithAlarm:(EWAlarm *)alarm {
    if ([EWSession sharedSession].wakeupStatus == EWWakeUpStatusWakingUp) {
        DDLogWarn(@"WakeUpManager is already handling alarm timer, skip");
        return NO;
    }
    EWActivity *activity = [EWPerson myCurrentAlarmActivity];
    //check alarm
    if (alarm && ![alarm.time.nextOccurTime isEqualToDate:activity.time]) {
        DDLogError(@"*** %s Alarm time (%@) doesn't match with activity time (%@), cancel wakeup process!", __func__, alarm.time.nextOccurTime.date2detailDateString, activity.time.date2detailDateString);
        //[[NSException exceptionWithName:@"EWInternalInconsistance" reason:@"Alarm and Activity mismatched" userInfo:@{@"alarm": alarm, @"activity;=": activity}] raise];
        return NO;
    }
    //check activity
    if (activity.completed && ![EWWakeUpManager shared].skipCheckActivityCompleted) {
        DDLogError(@"Activity is completed at %@, skip today's alarm. Please check the code", activity.completed.date2detailDateString);
        return NO;
    }
    else if (activity.time.timeElapsed > kMaxWakeTime) {
        DDLogInfo(@"Activity(%@) from notification has passed the wake up window. Handle it with complete activity.", activity.objectId);
        [[EWActivityManager sharedManager] completeAlarmActivity:activity];
        return NO;
    }
    else if (activity.time.timeIntervalSinceNow > kMaxEalyWakeInterval) {
        // too early to wake
        if ([EWWakeUpManager sharedInstance].forceWakeUp) {
            DDLogInfo(@"Time left %@ but forced wakeup", activity.time.timeLeft);
            return YES;
        }
        DDLogWarn(@"Wake %.1f hours early, skip.", activity.time.timeIntervalSinceNow/3600.0);
        // add unread media albeit too early to wake
        return NO;
    }
    
    return YES;
}
@end
