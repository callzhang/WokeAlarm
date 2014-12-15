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

@implementation EWAlarm


#pragma mark - NEW
//add new alarm, save, add to current user, save user
+ (EWAlarm *)newAlarm{
    NSParameterAssert([NSThread isMainThread]);
    DDLogVerbose(@"Create new Alarm");
    
    //add relationMagicalRecord
    EWAlarm *a = [EWAlarm MR_createEntity];
    a.updatedAt = [NSDate date];
    a.owner = [EWPerson me];
    a.state = @YES;
    a.tone = [EWPerson me].preference[@"DefaultTone"];
    
    return a;
}

#pragma mark - DELETE
- (void)remove{
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmDelete object:self userInfo:nil];
    [self MR_deleteEntity];
    [EWSync save];
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
        good = NO;
    }
    //check tone
    if (!self.tone) {
        DDLogError(@"Tone not set!");
        //self.tone = [EWPerson me].preference[@"DefaultTone"];
        good = NO;
    }
    
    if (!self.state) {
        DDLogError(@"State not set for alarm: %@", self.objectId);
    }
    
    if (!good) {
        DDLogError(@"Alarm failed validation: %@", self);
    }
    return good;
}

#pragma mark - response to changes
- (void)setState:(NSNumber *)state {
    //update cached time in person
    if (self.stateValue == state.boolValue) {
        DDLogInfo(@"Set same state to alarm: %@", self);
        return;
    }
    
    [self willChangeValueForKey:EWAlarmAttributes.state];
    [self setPrimitiveState:state];
    [self didChangeValueForKey:EWAlarmAttributes.state];
    
    if (![self validate]) {
        return;
    }
	//update saved time in user defaults
	//[self setSavedAlarmTime];
	//schedule local notification
	if (state.boolValue == YES) {
		//schedule local notif
		[self scheduleLocalNotification];
	} else {
		//cancel local notif
		[self cancelLocalNotification];
	}

    [[EWAlarmManager sharedInstance] scheduleNotificationOnServerForAlarm:self];
    [self updateCachedAlarmTime];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmStateChanged object:self];
}

- (void)setTime:(NSDate *)time {
    if ([self.time isEqualToDate:time]) {
        DDLogInfo(@"Set same time to alarm: %@", self);
        return;
    }
    
    [self willChangeValueForKey:EWAlarmAttributes.time];
    [self setPrimitiveTime:time];
    [self didChangeValueForKey:EWAlarmAttributes.time];
    if (![self validate]) {
        return;
    }
    //update saved time in user defaults
    //[self setSavedAlarmTime];
    
    //update cached alarm time in currentUser
    [self updateCachedAlarmTime];
    
    //schedule local notification
    [self scheduleLocalNotification];
    
    // schedule on server
    [[EWAlarmManager sharedInstance] scheduleNotificationOnServerForAlarm:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmTimeChanged object:self];
}

- (void)setTone:(NSString *)tone {
    if ([self.tone isEqualToString:tone]) {
        DDLogVerbose(@"Set same tone for alarm: %@", self.objectId);
        return;
    }
    [self willChangeValueForKey:EWAlarmAttributes.tone];
    [self setPrimitiveTone:tone];
    [self didChangeValueForKey:EWAlarmAttributes.tone];
    
    [self cancelLocalNotification];
    [self scheduleLocalNotification];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmToneChanged object:self];
}

- (void)setStatement:(NSString *)statement {
    [self willChangeValueForKey:EWAlarmAttributes.statement];
    [self setPrimitiveStatement:statement];
    [self didChangeValueForKey:EWAlarmAttributes.statement];
    [self updateCachedStatement];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmToneChanged object:self];
}


#pragma mark - Tools
//update saved time in user defaults
//- (void)setSavedAlarmTime{
//	NSInteger wkd = self.time.mt_weekdayOfWeek - 1;
//	double hour = self.time.mt_hourOfDay;
//	double minute = self.time.mt_minuteOfHour;
//	double number = round(hour*100 + minute)/100.0;
//    NSMutableArray *alarmTimes = [[[NSUserDefaults standardUserDefaults] objectForKey:kSavedAlarms] mutableCopy];
//	[alarmTimes setObject:[NSNumber numberWithDouble:number] atIndexedSubscript:wkd];
//	[[NSUserDefaults standardUserDefaults] setObject:alarmTimes.copy forKey:kSavedAlarms];
//}


#pragma mark - Cached alarm time to user defaults
//the alarm time stored in person's cached info
- (void)updateCachedAlarmTime{
    NSDictionary *cache = [EWPerson me].cachedInfo;
    NSString *wkday = self.time.mt_stringFromDateWithFullWeekdayTitle;
    NSString *path = [NSString stringWithFormat:@"%@.%@", kCachedAlarmTimes, wkday];
    [EWPerson me].cachedInfo = [cache setValue:self.time.nextOccurTime forImmutableKeyPath:path];

    [EWSync save];
    DDLogVerbose(@"Updated cached alarm times: %@ on %@", self.time.nextOccurTime, wkday);
}

- (void)updateCachedStatement{
    NSDictionary *cache = [EWPerson me].cachedInfo;
    NSString *wkday = self.time.mt_stringFromDateWithFullWeekdayTitle;
    NSString *path = [NSString stringWithFormat:@"%@.%@", kCachedStatements, wkday];
    [EWPerson me].cachedInfo = [cache setValue:self.statement forImmutableKeyPath:path];
    [EWSync save];
    DDLogVerbose(@"Updated cached statements: %@ on %@", self.statement, wkday);
}

#pragma mark - Local Notification
- (void)scheduleLocalNotification{
	//check state
    if (![self validate]) {
        DDLogVerbose(@"Alarm not validated when scheduling local notif");
        return;
    }
    
    if(!self.stateValue) {
        [self cancelLocalNotification];
    }
	
	//check existing
	NSMutableArray *notifications = [[self localNotifications] mutableCopy];
	
	//check missing timer
	for (unsigned i=0; i<nWeeksToSchedule; i++) {
        for (unsigned j = 0; j<nLocalNotifPerAlarm; j++) {
            //get time
            NSDate *time_j = [[self.time nextOccurTime:i] dateByAddingTimeInterval: j * 60];
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
			
			DDLogWarn(@"Unmatched alarm notification deleted (%@) ", ln.fireDate.date2detailDateString);
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
    if (!self.time) {
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
                    DDLogError(@"Found sleep notification with incorrect time %@, should be %@. (%@)", sleep.fireDate, sleepTime, sleepTime.mt_stringFromDateWithFullWeekdayTitle);
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
            DDLogError(@"Tring to schedule sleep timer in the past: %@", sleepTime.date2detailDateString);
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


@end
