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

- (EWActivity *)currentAlarmActivityForPerson:(EWPerson *)person{
    //EWAssertMainThread
    EWAlarm *alarm = [[EWAlarmManager sharedInstance] currentAlarmForPerson:person];
    
    //try to find current activity if nil
    if (!_currentAlarmActivity) {
        _currentAlarmActivity = [self activityForAlarm:alarm];
    }
    
    //validate: current activity if exists
    NSInteger n = 0;
    BOOL completed = _currentAlarmActivity.completed && ![EWWakeUpManager shared].skipCheckActivityCompleted;
    BOOL timeMatched = [_currentAlarmActivity.time isEqualToDate: alarm.time.nextOccurTime];
    while (_currentAlarmActivity && (completed || !timeMatched)) {
        DDLogWarn(@"%s Current activity completed or mismatch: %@", __FUNCTION__, _currentAlarmActivity.time.date2detailDateString);
        //invalid activity, try next
        _currentAlarmActivity = nil;
        alarm = [[EWAlarmManager sharedInstance] next:n thAlarmForPerson:person];
        _currentAlarmActivity = [self activityForAlarm:alarm];
        completed = _currentAlarmActivity.completed && ![EWWakeUpManager shared].skipCheckActivityCompleted;
        timeMatched = [_currentAlarmActivity.time isEqualToDate: alarm.time.nextOccurTime];
        n++;
    }
    
    //generate if needed
    if (!_currentAlarmActivity) {
        //create new activity
        if ([NSThread isMainThread]) {
            _currentAlarmActivity = [EWActivity newActivity];
        } else {
            __block EWActivity *activity;
            dispatch_sync(dispatch_get_main_queue(), ^{
                activity = [EWActivity newActivity];
            });
            _currentAlarmActivity = [activity MR_inContext:person.managedObjectContext];
        }
        
        _currentAlarmActivity.owner = person;
        _currentAlarmActivity.type = EWActivityTypeAlarm;
        _currentAlarmActivity.time = alarm.time.nextOccurTime;
        [_currentAlarmActivity save];
    }
    
    return _currentAlarmActivity;
}

- (EWActivity *)activityForAlarm:(EWAlarm *)alarm{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@ AND %K = %@ AND %K = %@", EWActivityAttributes.type, EWActivityTypeAlarm, EWActivityAttributes.time, alarm.time.nextOccurTime, EWActivityRelationships.owner, alarm.owner];
    NSMutableArray *activities = [EWActivity MR_findAllWithPredicate:predicate].mutableCopy;
    [activities sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.objectId ascending:YES],
                                       [NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.createdAt ascending:YES]]];
    while (activities.count >1) {
        EWActivity *activity = activities.firstObject;
        DDLogError(@"Multiple current alarm activities found, please check: \n%@", activity.serverID);
        [activities removeObject:activity];
        [activity remove];
    }
    
    return activities.lastObject;
}

- (void)completeAlarmActivity:(EWActivity *)activity{
    NSParameterAssert([activity.type isEqualToString:EWActivityTypeAlarm]);
    if (activity != self.currentAlarmActivity) {
        DDLogError(@"%s The activity passed in is not the current activity", __FUNCTION__);
    }else{
        //add unread medias to current media
        for (EWMedia *media in [EWPerson myUnreadMedias]) {
			if (media.played) {
				[activity addMediaID:media.objectId];
			}
        }
        NSArray *played = activity.medias;
        [[EWPerson me] removeUnreadMedias:[NSSet setWithArray:played]];
		[[EWPerson me] addReceivedMedias:[NSSet setWithArray:played]];
        DDLogInfo(@"Removed %ld medias from my unread medias", played.count);
    }
    
    activity.completed = [NSDate date];
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
        DDLogError(@"*** %s Alarm time (%@) doesn't match with activity time (%@), abord", __func__, alarm.time.nextOccurTime.date2detailDateString, activity.time.date2detailDateString);
        [[NSException exceptionWithName:@"EWInternalInconsistance" reason:@"Alarm and Activity mismatched" userInfo:@{@"alarm": alarm, @"activity;=": activity}] raise];
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
