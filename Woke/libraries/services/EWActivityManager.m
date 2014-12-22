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

- (instancetype)init{
    self = [super init];
    if (self) {
        //observe new media notification
        [[NSNotificationCenter defaultCenter] addObserverForName:kNewMediaNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            DDLogVerbose(@"Activity manager observed new media notification and added new media to my current alarm activity");
            EWMedia *newMedia = note.object;
            EWActivity *alarmActivity = [self myCurrentAlarmActivity];
            [alarmActivity addMediasObject:newMedia];
            [EWSync save];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTypeActivityHasNewMedia object:alarmActivity];
        }];
    }
    return self;
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
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@ AND %K = %@", EWActivityAttributes.type, EWActivityTypeAlarm, EWActivityAttributes.time, nextAlarm.time.nextOccurTime];
        NSArray *activities = [EWActivity MR_findAllWithPredicate:predicate];
        _currentAlarmActivity = activities.lastObject;
        if (activities.count > 1) {
            DDLogError(@"Multiple current alarm activities found, please check: \n%@", [activities valueForKey:EWActivityAttributes.time]);
        }
        
        if (!_currentAlarmActivity) {
            //create new activity
            _currentAlarmActivity = [EWActivity newActivity];
            _currentAlarmActivity.owner = [EWPerson me];
            _currentAlarmActivity.type = EWActivityTypeAlarm;
            _currentAlarmActivity.time = nextAlarm.time.nextOccurTime;
            //add unread media to current activity
            for (EWMedia *media in [EWPerson me].unreadMedias) {
                if (!media.targetDate || [media.targetDate timeIntervalSinceDate:nextAlarm.time.nextOccurTime]<0) {
                    [_currentAlarmActivity addMediasObject:media];
                }
            }
            //remove media from unreadMedias
            for (EWMedia *media in _currentAlarmActivity.medias) {
                [[EWPerson me] addUnreadMediasObject:media];
            }
            [EWSync save];
        }
    }else{
        if (fabs([_currentAlarmActivity.time timeIntervalSinceDate: nextAlarm.time.nextOccurTime])>1) {
            _currentAlarmActivity = nil;
            [self myCurrentAlarmActivity];
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
