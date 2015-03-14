//
//  EWAlarmItem.m
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWAlarm.h"
#import "EWSession.h"
#import "EWAlarmManager.h"
#import "NSDictionary+KeyPathAccess.h"
#import "EWActivityManager.h"
#import "EWActivity.h"
#import "NSDate+Extend.h"
#import "NSTimer+BlocksKit.h"
#import "NSDate+MTDates.h"

@implementation EWAlarm


#pragma mark - NEW
//add new alarm, save, add to current user, save  Ouser
+ (instancetype)newAlarm{
    EWAssertMainThread
    DDLogVerbose(@"Create new Alarm");
    
    //add relationMagicalRecord
    EWAlarm *a = [EWAlarm MR_createEntity];
    a.updatedAt = [NSDate date];
    a.owner = [EWPerson me];
    a.state = @YES;
    a.tone = [EWPerson me].preference[@"DefaultTone"];
    
    return a;
}

#pragma mark - Search
+ (instancetype)getAlarmByID:(NSString *)alarmID{
    EWAssertMainThread
    NSError *error;
    EWAlarm *alarm = (EWAlarm *)[EWSync findObjectWithClass:NSStringFromClass(self) withID:alarmID error:&error];
    if (error) {
        DDLogError(error.description);
    }
    return alarm;
}

+ (void)deleteAll{
    //delete
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (EWAlarm *alarm in [EWPerson me].alarms) {
            EWAlarm *localAlarm = [alarm MR_inContext:localContext];
            [localAlarm remove];
        }
    }];
}

#pragma mark - Validate alarm
- (BOOL)validate{
    BOOL good = YES;
    if (!self.owner) {
        DDLogError(@"Alarm（%@）missing owner", self.serverID);
        //self.owner = [[EWPerson me] MR_inContext:self.managedObjectContext];
        good = NO;
    }
    if (!self.time) {
        DDLogError(@"Alarm（%@）missing time", self.serverID);
		if (self.owner == [EWPerson meInContext:self.managedObjectContext]) {
            [self setPrimitiveTime:[[NSDate date] timeByMinutesFrom5am:180]];
			DDLogInfo(@"Fixed to %@", self.time.date2String);
		}else {
			good = NO;
		}
    }
    //check tone
    if (!self.tone) {
        DDLogError(@"Tone not set!");
		if (self.owner == [EWPerson meInContext:self.managedObjectContext]) {
			[self setPrimitiveTone:[EWPerson me].preference[@"DefaultTone"]];
			DDLogInfo(@"Fixed to %@", self.tone);
		}else {
			good = NO;
		}
    }
    
    if (!self.state) {
        DDLogError(@"State not set for alarm: %@", self.objectId);
		if (self.owner == [EWPerson me]) {
			[self setPrimitiveState:@YES];
			DDLogInfo(@"Fixed to %@", self.state);
		}else {
			good = NO;
		}
    }
    return good;
}

#pragma mark - response to changes
- (void)setState:(NSNumber *)state {
    //update cached time in person
    if (self.stateValue == state.boolValue) {
        //DDLogInfo(@"Set same state to alarm: %@", self);
        return;
    }

    [self willChangeValueForKey:EWAlarmAttributes.state];
    [self setPrimitiveState:state];
    [self didChangeValueForKey:EWAlarmAttributes.state];
    
    if (![self validate]) {
        return;
    }
    
    [self updateCachedAlarmTime];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmStateChanged object:self];

}

- (void)setTime:(NSDate *)time {
    if ([self.time isEqualToDate:time]) {
        //DDLogInfo(@"Set same time to alarm: %@", self);
        return;
    }
    
    
    EWActivity *activity = [[EWActivityManager sharedManager] activityForAlarm:self];
    
    [self willChangeValueForKey:EWAlarmAttributes.time];
    [self setPrimitiveTime:time];
    [self didChangeValueForKey:EWAlarmAttributes.time];
    if (![self validate]) return;
    
    //update activity's time
    activity.time = time.nextOccurTime;
    
    static NSTimer *timer;
    [timer invalidate];
    timer = [NSTimer bk_scheduledTimerWithTimeInterval:1 block:^(NSTimer *timer) {
        
        
        
    } repeats:NO];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmTimeChanged object:self];
    });
}

- (void)setTone:(NSString *)tone {
    if ([self.tone isEqualToString:tone]) {
        return;
    }
    [self willChangeValueForKey:EWAlarmAttributes.tone];
    [self setPrimitiveTone:tone];
    [self didChangeValueForKey:EWAlarmAttributes.tone];
    if (![self validate]) return;
    [self cancelLocalNotification];
    [self scheduleLocalNotification];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmToneChanged object:self];
}

- (void)setStatement:(NSString *)statement {
    [self willChangeValueForKey:EWAlarmAttributes.statement];
    [self setPrimitiveStatement:statement];
    [self didChangeValueForKey:EWAlarmAttributes.statement];
    if (![self validate]) return;
    [self updateCachedStatement];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmStatementChanged object:self];
}


#pragma mark - Cached alarm time to user defaults
//the alarm time stored in person's cached info
- (void)updateCachedAlarmTime{
    EWPerson *me = [EWPerson meInContext:self.managedObjectContext];
    NSDictionary *cache = me.cachedInfo;
    NSString *wkday = self.time.mt_stringFromDateWithFullWeekdayTitle;
    if (!wkday) return;
    me.cachedInfo = [cache setValue:self.time.nextOccurTime forImmutableKeyPath:@[kCachedAlarmTimes, wkday]];

    [me save];
    DDLogVerbose(@"Updated cached alarm times: %@ on %@", self.time.nextOccurTime, wkday);
}

- (void)updateCachedStatement{
    EWPerson *me = [EWPerson meInContext:self.managedObjectContext];
    NSDictionary *cache = me.cachedInfo;
    NSString *wkday = self.time.mt_stringFromDateWithFullWeekdayTitle;
    me.cachedInfo = [cache setValue:self.statement forImmutableKeyPath:@[kCachedStatements, wkday]];
    [me save];
    DDLogVerbose(@"Updated cached statements: %@ on %@", self.statement, wkday);
}

+ (NSDate *)getCachedAlarmTimeOnWeekday:(NSInteger)targetDay{
    EWAssertMainThread
    EWPerson *me = [EWPerson me];
    NSArray *weekdayStrings = [NSDate mt_weekdaySymbols];
    NSString *wkday = weekdayStrings[targetDay];
    NSDate *time = [me.cachedInfo valueForKeyPath:[NSString stringWithFormat:@"%@.%@", kCachedAlarmTimes, wkday]];
    if (!time) {
        time = [self getSavedAlarmTimeOnWeekday:targetDay];
    }
    DDLogVerbose(@"Get cached alarm times: %@", time.string);
    
    return time;
}

+ (NSDate *)getSavedAlarmTimeOnWeekday:(NSInteger)targetDay{
    //set weekday
    NSDate *today = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];//TIMEZONE
    NSDateComponents *comp = [NSDateComponents new];//used as a dic to hold time diff
    comp.day = targetDay - today.mt_weekdayOfWeek + 1;
    NSDate *time = [cal dateByAddingComponents:comp toDate:today options:0];//set the weekday
    comp = [cal components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:time];//get the target date
    NSArray *alarmTimes = defaultAlarmTimes;
    double number = [(NSNumber *)alarmTimes[targetDay] doubleValue];
    NSInteger hour = (NSInteger)floor(number);
    NSInteger minute = (NSInteger)round((number - hour)*100);
    comp.hour = hour;
    comp.minute = minute;
    time = [cal dateFromComponents:comp];
    DDLogVerbose(@"Get saved alarm time %@", time);
    return time;
}

#pragma mark - Notification
- (void)scheduleLocalAndPushNotification{
    // schedule on server
    [[EWAlarmManager sharedInstance] scheduleNotificationOnServerForAlarm:self];
    
    //update cached alarm time in currentUser
    [self updateCachedAlarmTime];
    
    //schedule local notification
    [self scheduleLocalNotification];
}

- (void)scheduleLocalNotification{
	//check state
    if (![self validate]) {
        DDLogVerbose(@"Alarm not validated when scheduling local notif");
        return;
    }
    
    if(!self.stateValue) {
        [self cancelLocalNotification];
        return;
    }
	
	//check existing
	NSMutableArray *notifications = [[self localNotifications] mutableCopy];
	
	//check missing timer
	for (unsigned i=0; i<nWeeksToSchedule; i++) {
        for (unsigned j = 0; j<nLocalNotifPerAlarm; j++) {
            //get time
            NSDate *time_j = [[self.time nextOccurTimeInWeeks:i] dateByAddingTimeInterval: j * 60];
            BOOL foundMatchingLocalNotif = NO;
            for (UILocalNotification *notification in notifications) {
                if ([time_j isEqualToDate:notification.fireDate]) {
                    //found matching notification
                    foundMatchingLocalNotif = YES;
                    [notifications removeObject:notification];
                    break;
                }
            }
            if (!foundMatchingLocalNotif) {
                
                //make self objectID perminent
                if (self.objectID.isTemporaryID) {
                    [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:NULL];
                }
                //schedule
                UILocalNotification *localNotif = [[UILocalNotification alloc] init];
                //set fire time
                localNotif.fireDate = time_j;
                localNotif.timeZone = [NSTimeZone systemTimeZone];
                if (self.statement) {
                    localNotif.alertBody = self.statement;
                }else{
                    localNotif.alertBody = NSLocalizedString(@"It's time to get up!", @"It's time to get up!");
                }
                
                localNotif.alertAction = NSLocalizedString(@"Get up!", @"Get up!");
                localNotif.soundName = self.tone;
                localNotif.applicationIconBadgeNumber = i+1;
                
                //======= user information passed to app delegate =======
                //Use Alarm's objectID as the identifier instead of serverID to avoid cases where alarm doesn't have one
                localNotif.userInfo = @{kLocalAlarmID: self.objectID.URIRepresentation.absoluteString,
                                        kLocalNotificationTypeKey: kLocalNotificationTypeAlarmTimer};
                //=======================================================
                
                if (i == nWeeksToSchedule - 1) {
                    //if this is the last one, schedule to be repeat
                    localNotif.repeatInterval = NSCalendarUnitWeekOfYear;
                }
                
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
                DDLogInfo(@"Local Notif scheduled at %@", localNotif.fireDate.date2detailDateString);
            }
        }
		
	}
	
	//delete remaining alarm timer
	for (UILocalNotification *ln in notifications) {
		if ([ln.userInfo[kLocalNotificationTypeKey] isEqualToString:kLocalNotificationTypeAlarmTimer]) {
			
			DDLogVerbose(@"Unmatched alarm notification deleted (%@) ", ln.fireDate.date2detailDateString);
			[[UIApplication sharedApplication] cancelLocalNotification:ln];
		}
		
	}
	
	//schedule sleep timer
	[self scheduleSleepLocalNotification];
	
}


- (void)cancelLocalNotification{
    NSArray *notifications = [self localNotifications];
    for(UILocalNotification *aNotif in notifications) {
        DDLogInfo(@"Local Notification cancelled for:%@", aNotif.fireDate.date2detailDateString);
        [[UIApplication sharedApplication] cancelLocalNotification:aNotif];
    }
}

- (NSArray *)localNotifications{
    NSMutableArray *notifArray = [[NSMutableArray alloc] init];
    for(UILocalNotification *aNotif in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if([aNotif.userInfo[kLocalAlarmID] isEqualToString:self.objectID.URIRepresentation.absoluteString]) {
            [notifArray addObject:aNotif];
        }
    }
    
    return notifArray;
}

#pragma mark - Sleep notification

- (void)scheduleSleepLocalNotification{
    if (!self.validate) {
        return;
    }
    if (!self.stateValue) {
        DDLogVerbose(@"Skip scheduling sleep notification for %@", self.time.date2detailDateString);
        return;
    }
    NSNumber *duration = [EWPerson me].preference[kSleepDuration];
    float d = duration.floatValue;
    NSDate *sleepTime = [self.time.nextOccurTime dateByAddingTimeInterval:-d*3600];
    BOOL sleepNotificationScheduled = NO;
    for (UILocalNotification *sleep in self.localNotifications) {
        if ([sleep.userInfo[kLocalNotificationTypeKey] isEqualToString:kLocalNotificationTypeSleepTimer]) {
            if ([sleep.userInfo[kLocalAlarmID] isEqualToString:self.objectID.URIRepresentation.absoluteString]) {
                if ([sleep.fireDate isEqualToDate:sleepTime]) {
                    sleepNotificationScheduled = YES;
                }else{
                    DDLogError(@"Found sleep notification with incorrect time %@, should be %@.", sleep.fireDate.date2detailDateString, sleepTime.date2detailDateString);
                    [[UIApplication sharedApplication] cancelLocalNotification:sleep];
                }
                
            }
        }
    }
    
    if (!sleepNotificationScheduled) {
        //local notification
        UILocalNotification *sleepNotif = [[UILocalNotification alloc] init];
        sleepNotif.timeZone = [NSTimeZone systemTimeZone];
        sleepNotif.alertBody = [NSString stringWithFormat:@"It's time to sleep, press here to enter sleep mode (%@)", sleepTime.date2String];
        sleepNotif.alertAction = @"Sleep";
        sleepNotif.repeatInterval = NSCalendarUnitWeekOfYear;
        sleepNotif.soundName = @"sleep mode.caf";
        sleepNotif.userInfo = @{kLocalAlarmID: self.objectID.URIRepresentation.absoluteString,
                                kLocalNotificationTypeKey: kLocalNotificationTypeSleepTimer};
        if ([sleepTime timeIntervalSinceNow]>0) {
            sleepNotif.fireDate = sleepTime;
        }else{
            DDLogDebug(@"Tring to schedule sleep timer in the past: %@", sleepTime.date2detailDateString);
            return;
        }
        
        [[UIApplication sharedApplication] scheduleLocalNotification:sleepNotif];
        DDLogInfo(@"Sleep notification schedule at %@", sleepNotif.fireDate.date2detailDateString);
    }
}

- (void)cancelSleepLocalNotification{
    NSArray *sleeps = [UIApplication sharedApplication].scheduledLocalNotifications;
    NSInteger n = 0;
    for (UILocalNotification *sleep in sleeps) {
        if ([sleep.userInfo[kLocalNotificationTypeKey] isEqualToString:kLocalNotificationTypeSleepTimer]) {
            if ([sleep.userInfo[kLocalAlarmID] isEqualToString:self.objectID.URIRepresentation.absoluteString]) {
                [[UIApplication sharedApplication] cancelLocalNotification:sleep];
                n++;
            }
        }
    }
    DDLogInfo(@"Cancelled %ld sleep notification", (long)n);
}

- (EWServerObject *)ownerObject{
    return self.owner;
}

@end
