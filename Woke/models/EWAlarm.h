//
//  EWAlarmItem.h
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "_EWAlarm.h"

@interface EWAlarm : _EWAlarm

// add
+ (EWAlarm *)newAlarm;

// delete
- (void)remove;

//validate
- (BOOL)validate;

//timer local notification
/**
 Schedule both timer and sleep notification
 */
- (void)scheduleLocalNotification;
- (void)scheduleAlarmTimerLocalNotification;
- (void)scheduleSleepLocalNotification;
/**
 cancel both timer and sleep notification
 */
- (void)cancelLocalNotification;
- (void)cancelAlarmTimerLocalNotification;
- (void)cancelSleepLocalNotification;
- (NSArray *)localNotifications;//both sleep and timer

@end