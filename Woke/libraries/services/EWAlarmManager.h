//
//  EWAlarmManager.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-8.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWSession.h"
#define kCachedAlarmTimes                @"alarm_schedule"
#define kCachedStatements                @"statements"


@class EWAlarm, EWPerson;

@interface EWAlarmManager : NSObject
@property BOOL isSchedulingAlarms;

// Singleton
+ (EWAlarmManager *)sharedInstance;

/**
 *  Get next alarm time from person's cachedInfo
 *
 *  @param person Any person, could be me or others
 *
 *  @return next valid alarm time
 */
- (NSDate *)nextAlarmTimeForPerson:(EWPerson *)person;
//Get next alarm statement from person's cachedInfo
- (NSString *)nextStatementForPerson:(EWPerson *)person;
/**
 *  current valid alarm for person. It first finds the next alarm that is turned on. then, look for activity for that alarm and make sure that activity is not completed, otherwise the next valid alarm is returned.
 *
 *  @param person Person should be me, or otherwise return nil
 *
 *  @return person's next valid alarm
 */
- (EWAlarm *)currentAlarmForPerson:(EWPerson *)person;
/**
 *  next N'th alarm for person
 *
 *  @param n      0 for current and 1 for next...
 *  @param person target person, must be me
 *
 *  @return the desired alarm
 */
- (EWAlarm *)next:(NSInteger)n thAlarmForPerson:(EWPerson *)person;
//alarm sorted by weekdays
- (NSArray *)alarmsForPerson:(EWPerson *)person;

// schedule + check
- (NSArray *)scheduleAlarm;
- (void)checkAlarmsFromServer;

//update cached info
- (void)updateCachedAlarmTimes;
- (void)updateCachedStatements;

//UTIL
- (NSDate *)getSavedAlarmTimeOnWeekday:(NSInteger)wkd;

//local notification
- (void)checkScheduledLocalNotifications;
- (void)scheduleAllNotifications;
- (void)scheduleSleepNotifications;
- (void)cancelAllNotifications;
- (void)cancelSleepNotifications;


/*
 Use REST to create a notification on server
 when person is in his sleep mode
 */
#define kScheduledAlarmTimers       @"scheduled_alarm_timers"
- (void)scheduleNotificationOnServerForAlarm:(EWAlarm *)alarm;
@end
