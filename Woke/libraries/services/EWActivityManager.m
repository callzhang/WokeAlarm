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
    EWAssertMainThread
    EWAlarm *alarm = [[EWAlarmManager sharedInstance] currentAlarmForPerson:person];
    NSInteger n = 1;
    
    //validate: current activity has to be either nil or valide
    while (_currentAlarmActivity &&
           (_currentAlarmActivity.completed || ![_currentAlarmActivity.time isEqual: alarm.time.nextOccurTime])) {
        DDLogVerbose(@"%s activity completed or mismatch: %@", __FUNCTION__, _currentAlarmActivity);
        //invalid activity, try next
        _currentAlarmActivity = nil;
        alarm = [[EWAlarmManager sharedInstance] next:n thAlarmForPerson:person];
        _currentAlarmActivity = [self activityForAlarm:alarm];
    }
    
    //generate if needed
    if (!_currentAlarmActivity) {
        //create new activity
        _currentAlarmActivity = [EWActivity newActivity];
        _currentAlarmActivity.owner = person;
        _currentAlarmActivity.type = EWActivityTypeAlarm;
        _currentAlarmActivity.time = alarm.time.nextOccurTime;
        [EWSync save];
    }
    
    return _currentAlarmActivity;
}

- (EWActivity *)activityForAlarm:(EWAlarm *)alarm{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@ AND %K = %@ AND %K = %@", EWActivityAttributes.type, EWActivityTypeAlarm, EWActivityAttributes.time, alarm.time.nextOccurTime, EWActivityRelationships.owner, alarm.owner];
    NSArray *activities = [EWActivity MR_findAllWithPredicate:predicate];
    activities = [activities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.createdAt ascending:YES]]];
    if (activities.count > 1) {
        DDLogError(@"Multiple current alarm activities found, please check: \n%@", [activities valueForKey:EWActivityAttributes.time]);
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
            [activity addMediaID:media.objectId];
        }
        [EWPerson me].unreadMedias = nil;
    }
    
    activity.completed = [NSDate date];
    self.currentAlarmActivity = nil;
}

@end
