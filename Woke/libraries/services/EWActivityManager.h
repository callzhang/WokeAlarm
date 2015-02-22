//
//  EWActivityManager.h
//  Woke
//
//  Created by Lei Zhang on 10/29/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"
#import "EWWakeUpManager.h"

//#define kNotificationTypeActivityHasNewMedia    @"activity_new_media"

extern NSString *const EWActivityTypeAlarm;
extern NSString *const EWActivityTypeFriendship;
extern NSString *const EWActivityTypeMedia;

@interface EWActivityManager : NSObject <EWWakeUpDelegate>
/**
 *  Get the acitivity that is for current alarm
 *  If current activity is completed or mismatch with current alarm, generate a new activity
 *  The returned activity is the next valid alarm activity that is neither completed or 
 */
@property (nonatomic, strong) EWActivity *currentAlarmActivity;
+ (EWActivityManager *)sharedManager;

//methods
- (NSArray *)activitiesForPerson:(EWPerson *)person;

/**
 *  Find activity by alarm. The activity is matched with type == alarm, time == alarm.time.nextOccurTime AND owner == alarm.owner
 *
 *  @param alarm The alarm in interest
 *
 *  @return Activity matched with given criteria
 */
- (EWActivity *)activityForAlarm:(EWAlarm *)alarm;

/**
 *  Current activity for current alarm. If the current activity is completed, or not matched with current alarm, this function will generate a new activity
 *
 *  @param person Me
 *
 *  @return current activity
 */
- (EWActivity *)currentAlarmActivityForPerson:(EWPerson *)person;
- (void)completeAlarmActivity:(EWActivity *)activity;

@end
