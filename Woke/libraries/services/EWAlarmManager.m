//
//  EWAlarmManager.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-8.
//  Copyright (c) 2013年 Shens. All rights reserved.
//
// Alarms schedule/delete/create in batch of 7. Notification of save sent out at saveAlarms

#import "EWAlarmManager.h"
#import "NSDate+Extend.h"
#import "NSString+Extend.h"
#import "EWUtil.h"
#import "EWAlarm.h"
#import "EWPerson.h"
#import "EWPersonManager.h"

#import "EWAlarmScheduleViewController.h"

#import "AFNetworking.h"

@implementation EWAlarmManager

+ (EWAlarmManager *)sharedInstance {
    //make sure core data stuff is always on main thread
    //NSParameterAssert([NSThread isMainThread]);
    static EWAlarmManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWAlarmManager alloc] init];
    }); 
    
    return manager;
}

- (EWAlarmManager *)init{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alarmChanged:) name:kAlarmTimeChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alarmChanged:) name:kAlarmStateChanged object:nil];
    }
    return self;
}

#pragma mark - alarm changed
- (void)alarmChanged:(NSNotification *)note{
    EWAlarm *alarm = note.object;
    if ([note.name isEqualToString:kAlarmTimeChanged]) {
        [self scheduleNotificationOnServerForAlarm:alarm];
    }else if ([note.name isEqualToString:kAlarmStateChanged]){
        if (alarm.stateValue) {
            [self scheduleNotificationOnServerForAlarm:alarm];
        }
    }
}


#pragma mark - SEARCH
- (NSDate *)nextAlarmTimeForPerson:(EWPerson *)person{
    NSDate *nextTime;
    //first try to get it from cache
    NSDictionary *times = person.cachedInfo[kCachedAlarmTimes];
    if (!times && person.isMe) {
        [self updateCachedAlarmTimes];
    }
    
    for (NSDate *time in times.allValues) {
        NSDate *t = [time nextOccurTime:0];
        if (!nextTime || [t isEarlierThan:nextTime]) {
            nextTime = t;
        }
    }
    return nextTime;
}

- (NSString *)nextStatementForPerson:(EWPerson *)person{
    //first try to get it from cache
    NSDictionary *statements = person.cachedInfo[kCachedStatements];
    NSDictionary *times = person.cachedInfo[kCachedAlarmTimes];
    if (!statements && person.isMe) {
        [self updateCachedStatements];
    }
    if (!times && person.isMe) {
        [self updateCachedAlarmTimes];
    }
    
    __block NSString *nextWeekday;
    NSDate *nextTime;
    [times enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDate *time, BOOL *stop) {
        NSDate *t = [time nextOccurTime:0];
        if (!nextTime || [t isEarlierThan:nextTime]) {
            nextWeekday = key;
        }
    }];
    NSString *nextStatement = statements[nextWeekday];
    return nextStatement?:@"";
}



- (NSArray *)alarmsForPerson:(EWPerson *)user{
    NSMutableArray *alarms = [[user.alarms allObjects] mutableCopy];
    
    NSComparator alarmComparator = ^NSComparisonResult(id obj1, id obj2) {
        NSInteger wkd1 = [(EWAlarm *)obj1 time].mt_weekdayOfWeek - 1;
        NSInteger wkd2 = [(EWAlarm *)obj2 time].mt_weekdayOfWeek - 1;
        if (wkd1 > wkd2) {
            return NSOrderedDescending;
        }else if (wkd1 < wkd2){
            return NSOrderedAscending;
        }else{
            return NSOrderedSame;
        }
    };
    
    //sort
    NSArray *sortedAlarms = [alarms sortedArrayUsingComparator:alarmComparator];
    
    return sortedAlarms;
}

- (EWAlarm *)nextAlarmForPerson:(EWPerson *)person {
    float interval = CGFLOAT_MAX;
    EWAlarm *next;
    for (EWAlarm *alarm in [self alarmsForPerson:person]) {
        float timeLeft = alarm.time.nextOccurTime.timeIntervalSinceNow;
        //if (alarm.state) {
            if (interval == 0 || timeLeft < interval) {
                interval = timeLeft;
                next = alarm;
            }
        //}
    }
    return next;
}

#pragma mark - SCHEDULE
//schedule according to alarms array. If array is empty, schedule according to default template.
- (NSArray *)scheduleAlarm{
    NSParameterAssert([NSThread isMainThread]);
    if ([EWSession sharedSession].isSchedulingAlarm) {
        DDLogVerbose(@"Skip scheduling alarm because it is scheduling already!");
        return nil;
    }
    [EWSession sharedSession].isSchedulingAlarm = YES;
    
    //get alarms
    NSMutableArray *alarms = [[EWPerson myAlarms] mutableCopy];
    BOOL hasChange = NO;
    
    if (alarms.count == 0 && [EWSync isReachable]) {
        [self checkAlarmsFromServer];
        alarms = [[EWPerson myAlarms] mutableCopy];
    }
    
    //Fill array with alarm, delete redundency
    NSMutableArray *newAlarms = [@[@NO, @NO, @NO, @NO, @NO, @NO, @NO] mutableCopy];
    //check if alarm scheduled are duplicated
    for (EWAlarm *a in alarms) {
        
        //get the day alarm represents
        NSInteger i = a.time.mt_weekdayOfWeek-1;
        
        //see if that day has alarm already
        if (![newAlarms[i] isEqual:@NO]){
            //remove duplicacy
            DDLogWarn(@"@@@ Duplicated alarm found. Delete! %@", a.time.date2detailDateString);
            [a MR_deleteEntity];
            hasChange = YES;
            continue;
        }else if (![a validate]){
            DDLogError(@"%s Something wrong with alarm(%@) Delete!", __func__, a.objectId);
            [a MR_deleteEntity];
            hasChange = YES;
            continue;
        }
        
        
        //fill that day to the new alarm array
        newAlarms[i] = a;
    }
    
    //remove excess
    [alarms removeObjectsInArray:newAlarms];
    for (EWAlarm *a in alarms) {
        DDLogError(@"Corruped or duplicated alarm found and deleted: %@", a.serverID);
        [a remove];
        hasChange = YES;
    }
    
    //start add alarm if blank
    for (NSUInteger i=0; i<newAlarms.count; i++) {
        if (![newAlarms[i] isEqual:@NO]) {
            //skip if alarm exists
            continue;
        }
    
        DDLogVerbose(@"Alarm for weekday %ld missing, start add alarm", (long)i);
        EWAlarm *a = [EWAlarm newAlarm];
        
        //get time
        NSDate *time = [self getSavedAlarmTimeOnWeekday:i];
        //set alarm time
        a.time = time;
        //add to temp array
        newAlarms[i] = a;
        hasChange = YES;
        
    }
    
    //save
    if (hasChange) {
        //notification
        DDLogVerbose(@"Saving new alarms");
        [EWSync save];
//        
//        //notification
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            //delay here to make sure the thread don't compete at the same time
//            [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmChanged object:self userInfo:nil];
//        });
        
    }
    
    [EWSession sharedSession].isSchedulingAlarm = NO;
    
    return newAlarms;
}

- (void)checkAlarmsFromServer{
    BOOL hasChange = NO;
    //get alarms
    NSMutableArray *alarms = [[EWPerson myAlarms] mutableCopy];
    
    //check from server for alarm with owner but lost relation
    if (alarms.count != 7 && [EWSync isReachable]) {
        //cannot check alarm for myself, which will cause a checking/schedule cycle
        
        DDLogVerbose(@"Alarm for me is %lu, fetch from server!", alarms.count);
        PFQuery *alarmQuery = [PFQuery queryWithClassName:NSStringFromClass([EWAlarm class])];
        [alarmQuery whereKey:EWAlarmRelationships.owner equalTo:[PFUser currentUser]];
        [alarmQuery whereKey:kParseObjectID notContainedIn:[alarms valueForKey:kParseObjectID]];
        NSArray *objects = [EWSync findServerObjectWithQuery:alarmQuery error:NULL];
        
        for (PFObject *a in objects) {
            EWAlarm *alarm = (EWAlarm *)[a managedObjectInContext:mainContext];;
            [alarm refresh];
            alarm.owner = [EWPerson me];
            if (![alarm validate]) {
                [alarm remove];
            }else if (![alarms containsObject:alarm]) {
                [alarms addObject:alarm];
                hasChange = YES;
                DDLogVerbose(@"Alarm found from server %@", alarm);
            }
        }
    }
    
    if (hasChange) {
        [EWSync save];
    }
}

#pragma mark - Get/Set alarm to UserDefaults
- (NSDate *)getSavedAlarmTimeOnWeekday:(NSInteger)targetDay{
    //set weekday
    NSDate *today = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];//TIMEZONE
    NSDateComponents *comp = [NSDateComponents new];//used as a dic to hold time diff
    comp.day = targetDay - today.mt_weekdayOfWeek-1;
    NSDate *time = [cal dateByAddingComponents:comp toDate:today options:0];//set the weekday
    comp = [cal components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:time];//get the target date
    NSArray *alarmTimes = [self getSavedAlarmTimes];
    double number = [(NSNumber *)alarmTimes[targetDay] doubleValue];
    NSInteger hour = (NSInteger)floor(number);
    NSInteger minute = (NSInteger)round((number - hour)*100);
    comp.hour = hour;
    comp.minute = minute;
    time = [cal dateFromComponents:comp];
    DDLogVerbose(@"Get saved alarm time %@", time);
    return time;
}



//Get saved time in user defaults
- (NSArray *)getSavedAlarmTimes{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *alarmTimes = [defaults valueForKey:kSavedAlarms];
    //create if not exsit
    if (!alarmTimes) {
        //if asking saved value, the alarm is not scheduled
        DDLogInfo(@"=== Saved alarm time not found, use default values!");
        alarmTimes = defaultAlarmTimes;
        [defaults setObject:alarmTimes forKey:kSavedAlarms];
        [defaults synchronize];
    }
    return alarmTimes;
}

#pragma mark - Person cachedInfo updates
- (void)updateCachedAlarmTimes{
    //TODO
}
- (void)updateCachedStatements{
    //TODO
}



#pragma mark - Alarm timer local notofication
- (void)checkScheduledLocalNotifications{
	NSParameterAssert([NSThread isMainThread]);
	NSMutableArray *allNotification = [[[UIApplication sharedApplication] scheduledLocalNotifications] mutableCopy];
	DDLogInfo(@"There are %ld scheduled local notification", (long)allNotification.count);
	
	//delete redundant alarm notif
	for (EWAlarm *alarm in [EWPerson me].alarms) {
		[alarm scheduleLocalNotification];
		NSArray *notifs= [alarm localNotifications];
		[allNotification removeObjectsInArray:notifs];
	}
	
	for (UILocalNotification *aNotif in allNotification) {
		
		NSLog(@"===== Deleted %@ (%@) =====", aNotif.userInfo[kLocalNotificationTypeKey], aNotif.fireDate.date2detailDateString);
		[[UIApplication sharedApplication] cancelLocalNotification:aNotif];
		
	}
	
	if (allNotification.count > 0) {
		//make sure the redundent notif didn't prevent scheduling of new notification
		[self checkScheduledLocalNotifications];
	}
	
}


#pragma mark - Local notification
- (void)scheduleAlarmTimerNotifications{
    NSArray *alarms = [EWPerson myAlarms];
    for (EWAlarm *alarm in alarms) {
        [alarm scheduleAlarmTimerLocalNotification];
    }
}

- (void)scheduleSleepNotifications{
    NSArray *alarms = [EWPerson myAlarms];
    for (EWAlarm *alarm in alarms) {
        [alarm scheduleSleepLocalNotification];
    }
}

- (void)cancelSleepNotifications{
    NSArray *alarms = [EWPerson myAlarms];
    for (EWAlarm *alarm in alarms) {
        [alarm cancelSleepLocalNotification];
    }
}

- (void)cancelAlarmTimerNotifications{
    NSArray *alarms = [EWPerson myAlarms];
    for (EWAlarm *alarm in alarms) {
        [alarm cancelAlarmTimerLocalNotification];
    }
}

#pragma mark - Schedule Alarm Timer

- (void)scheduleNotificationOnServerForAlarm:(EWAlarm *)alarm{
    if (!alarm.time) {
        DDLogError(@"*** The Alarm for schedule push doesn't have time: %@", alarm);
        return;
    }else if (!alarm.objectId){
        [EWSync saveWithCompletion:^{
            [self scheduleNotificationOnServerForAlarm:alarm];
        }];
        return;
    }
    
    if ([alarm.time.nextOccurTime timeIntervalSinceNow] < 0) {
        DDLogWarn(@"The alarm you are trying to schedule on server is in the past: %@", alarm);
        return;
    }
    NSString *alarmID = alarm.serverID;
    NSDate *time = alarm.time;
    //check local schedule records before make the REST call
    __block NSMutableDictionary *timeTable = [[[NSUserDefaults standardUserDefaults] objectForKey:kScheduledAlarmTimers] mutableCopy] ?:[NSMutableDictionary new];

    NSMutableArray *timers = [timeTable[alarmID] mutableCopy];
    //delete past timer
    for (NSDate *t in timers) {
        if (t.timeElapsed > 0) {
            //remove past times
            [timers removeObject:t];
            [timeTable setObject:timers forKey:alarmID];
            DDLogVerbose(@"Past schedule alarm timer removed from time table: %@", t);
        }
    };
    //add new timer
    if ([timers containsObject:time]) {
        DDLogInfo(@"===Task (%@) timer push (%@) has already been scheduled on server, skip.", alarmID, time);
        return;
    }
    
    
    //============ Start scheduling task timer on server ============
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    [manager.requestSerializer setValue:kParseApplicationId forHTTPHeaderField:@"X-Parse-Application-Id"];
    [manager.requestSerializer setValue:kParseRestAPIId forHTTPHeaderField:@"X-Parse-REST-API-Key"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
    NSDictionary *dic = @{@"where":@{kUsername:[EWPerson me].username},
                          @"push_time":[NSNumber numberWithDouble:[time timeIntervalSince1970]+30],
                          @"data":@{@"alert":@"Time to get up",
                                    @"content-available":@1,
                                    kPushType: kPushTypeAlarmTimer,
                                    kPushAlarmID: alarmID},
                          };
    
    [manager POST:kParsePushUrl parameters:dic
          success:^(AFHTTPRequestOperation *operation,id responseObject) {
              
              DDLogVerbose(@"SCHEDULED alarm timer PUSH success for time %@", time.date2detailDateString);
              [timers addObject:time];
              [timeTable setObject:timers forKey:alarmID];
              [[NSUserDefaults standardUserDefaults] setObject:timeTable.copy forKey:kScheduledAlarmTimers];
              
          }failure:^(AFHTTPRequestOperation *operation,NSError *error) {
              
              DDLogError(@"Schedule Push Error: %@", error);
              
          }];
    
}

@end
