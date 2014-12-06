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

+ (NSArray *)myActivities{
    return [[EWActivityManager sharedManager] activitiesForPerson:[EWPerson me] inContext:nil];
}

+ (NSArray *)myAlarmActivities{
    NSArray *activities = [self myActivities];
    NSArray *alarmActivities = [activities bk_select:^BOOL(EWActivity *obj) {
        return [obj.type isEqualToString:EWActivityTypeAlarm] ? YES : NO;
    }];
    return alarmActivities;
}

- (NSArray *)activitiesForPerson:(EWPerson *)person inContext:(NSManagedObjectContext *)context{
    if (!context) {
        context = [NSManagedObjectContext MR_defaultContext];
    }
    EWPerson *localMe = [[EWPerson me] MR_inContext:context];
    NSArray *activities = localMe.activities.allObjects;
    activities = [activities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.updatedAt ascending:NO]]];
    return activities;
}

- (EWActivity *)myCurrentAlarmActivity{
    
    EWAlarm *nextAlarm = [EWPerson myCurrentAlarm];
    
    if (!_currentAlarmActivity) {
        NSArray *activities = [EWActivityManager myActivities];
        NSArray *alarmActivities = [activities bk_select:^BOOL(EWActivity *obj) {
            return [obj.type isEqualToString:EWActivityTypeAlarm] ? YES : NO;
        }];
        EWActivity *lastAlarmActivity = alarmActivities.lastObject;
        if (lastAlarmActivity && fabs([lastAlarmActivity.time timeIntervalSinceDate: nextAlarm.time.nextOccurTime])<1) {
            //the last activity is the current activity
            _currentAlarmActivity = lastAlarmActivity;
        }else{
            //create new activity
            _currentAlarmActivity = [EWActivity newActivity];
            _currentAlarmActivity.owner = [EWPerson me];
            _currentAlarmActivity.type = EWActivityTypeAlarm;
            _currentAlarmActivity.time = nextAlarm.time.nextOccurTime;
        }
    }else{
        if (fabs([_currentAlarmActivity.time timeIntervalSinceDate: nextAlarm.time.nextOccurTime])>1) {
            _currentAlarmActivity = nil;
            return self.currentAlarmActivity;
        }
    }
    return _currentAlarmActivity;
}

- (void)completeAlarmActivity:(EWActivity *)activity{
    NSParameterAssert([activity.type isEqualToString:EWActivityTypeAlarm]);
    //TODO
    activity.completed = [NSDate date];
    self.currentAlarmActivity = nil;
}

@end
