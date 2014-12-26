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
        /* no need to observe new media
        //observe new media notification
        [[NSNotificationCenter defaultCenter] addObserverForName:kNewMediaNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            DDLogVerbose(@"Activity manager observed new media notification and added new media to my current alarm activity");
            EWMedia *newMedia = note.object;
            EWActivity *alarmActivity = [EWPerson myCurrentAlarmActivity];
            NSMutableArray *mediaArray = alarmActivity.mediaIDs.mutableCopy;
            [mediaArray addObject:newMedia.objectId];
            alarmActivity.mediaIDs = mediaArray.copy;
            [EWSync save];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTypeActivityHasNewMedia object:alarmActivity];
        }];
         */
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

- (EWActivity *)currentAlarmActivityForPerson:(EWPerson *)person{
    EWAlarm *nextAlarm = [[EWAlarmManager sharedInstance] nextAlarmForPerson:person];
    
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
            _currentAlarmActivity.owner = person;
            _currentAlarmActivity.type = EWActivityTypeAlarm;
            _currentAlarmActivity.time = nextAlarm.time.nextOccurTime;
            [EWSync save];
        }
    }else{
        if (fabs([_currentAlarmActivity.time timeIntervalSinceDate: nextAlarm.time.nextOccurTime])>1) {
            _currentAlarmActivity = nil;
            [self currentAlarmActivityForPerson:person];
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
