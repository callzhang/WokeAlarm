//
//  EWWakeUpManager.m
//  EarlyWorm
//
//  Created by Lei on 3/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWWakeUpManager.h"
#import "EWPersonManager.h"
#import "EWAVManager.h"
#import "EWMedia.h"
#import "EWMediaManager.h"
#import "EWNotificationManager.h"
#import "EWPerson.h"

#import "EWServer.h"
#import "ATConnect.h"
#import "EWBackgroundingManager.h"
#import "EWAlarm.h"
#import "EWActivity.h"
#import "EWActivityManager.h"
#import "EWAlarmManager.h"
#import "NSTimer+BlocksKit.h"

@implementation EWWakeUpManager

+ (EWWakeUpManager *)sharedInstance{
    static EWWakeUpManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWWakeUpManager alloc] init];
    });
    return manager;
}

- (id)init{
	self = [super init];
    if ([EWSession sharedSession].isWakingUp) {
        self.medias = [EWPerson myUnreadMedias];
    }else{
        [self reloadMedias];
    }
    
    self.continuePlay = YES;
	[[NSNotificationCenter defaultCenter] addObserverForName:kBackgroundingStartNotice object:nil queue:nil usingBlock:^(NSNotification *note) {
		[self alarmTimerCheck];
		[self sleepTimerCheck];
	}];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextVoiceWithPause) name:kAVManagerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMedias) name:kNewMediaNotification object:nil];
    
    //first time loop
    self.loopCount = kLoopMediaPlayCount;
    
	return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Handle events
- (void)startToWakeUp:(NSDictionary *)info{
    /*
     There are a few entries here:
     1. from Push notifiaction: detected by kPushAlarmID
     2. from local notification: detected by kLocalAlarmID
     3. from sleep timer event: detected by kActivityID
     4. manual button pressed: pass in nil
     */
    EWAssertMainThread
    if ([EWSession sharedSession].isWakingUp) {
        DDLogWarn(@"WakeUpManager is already handling alarm timer, skip");
        return;
    }else if ([EWWakeUpManager isRootPresentingWakeUpView]) {
		DDLogWarn(@"WakeUpView is already presented, skip");
		return;
	}
    
    BOOL isLaunchedFromLocalNotification = NO;
    BOOL isLaunchedFromRemoteNotification = NO;
    BOOL isLaunchedFromAlarmTimer = NO;
	
    //alarm is a reference info from notification, also used to cancel local notification
	EWAlarm *alarm = [EWPerson myCurrentAlarm];
    //activity tells if the activity is completed or not
    EWActivity *activity = [EWPerson myCurrentAlarmActivity];
    if (info) {
        NSString *alarmID = info[kPushAlarmID];
        NSString *alarmLocalID = info[kLocalAlarmID];
        NSString *activityID = info[kActivityLocalID];
        NSParameterAssert(alarmID || alarmLocalID || activityID);
        if (alarmID) {
            isLaunchedFromRemoteNotification = YES;
            alarm = [EWAlarm getAlarmByID:alarmID];
        }else if (alarmLocalID) {
            isLaunchedFromLocalNotification = YES;
            NSURL *url = [NSURL URLWithString:alarmLocalID];
            NSManagedObjectID *ID = [mainContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
            if (ID) {
                alarm = (EWAlarm *)[mainContext existingObjectWithID:ID error:NULL];
            }else{
                DDLogError(@"The task objectID is invalid for alarm timer local notif: %@",alarmLocalID);
                alarm = [EWPerson myCurrentAlarm];
            }
        }else if (activityID) {
            isLaunchedFromAlarmTimer = YES;
            NSURL *url = [NSURL URLWithString:alarmLocalID];
            NSManagedObjectID *ID = [mainContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
            if (ID) {
                activity = (EWActivity *)[mainContext existingObjectWithID:ID error:NULL];
            }else{
                DDLogError(@"The task objectID is invalid for alarm timer local notif: %@",alarmLocalID);
                activity = [EWActivity getActivityWithID:activityID];
            }
        }
	}
    
    //check alarm
    if (alarm && ![alarm.time.nextOccurTime isEqualToDate:activity.time]) {
        DDLogError(@"*** %s Alarm time (%@) doesn't match with activity time (%@), abord", __func__, alarm.time.nextOccurTime.date2detailDateString, activity.time.date2detailDateString);
        [[NSException exceptionWithName:@"EWInternalInconsistance" reason:@"Alarm and Activity mismatched" userInfo:@{@"alarm": alarm, @"activity;=": activity}] raise];
    }
    //check activity
    if (activity.completed) {
        DDLogError(@"Activity is completed at %@, skip today's alarm. Please check the code", activity.completed.date2detailDateString);
        return;
    }
    else if (activity.time.timeElapsed > kMaxWakeTime) {
        DDLogInfo(@"Activity(%@) from notification has passed the wake up window. Handle it with complete activity.", activity.objectId);
        [[EWActivityManager sharedManager] completeAlarmActivity:activity];
        return;
    }
    else if (activity.time.timeIntervalSinceNow > kMaxEalyWakeInterval) {
        // too early to wake
        DDLogWarn(@"Wake %.1f hours early, skip.", activity.time.timeIntervalSinceNow/3600.0);
        // add unread media albeit too early to wake
        self.medias = [EWPerson myUnreadMedias];
        return;
    }
    
    DDLogInfo(@"Start handle timer event");
    //state change
    [EWSession sharedSession].isSleeping = NO;
    [EWSession sharedSession].isWakingUp = YES;
    
    //update media
    [[EWMediaManager sharedInstance] checkUnreadMedias];
    NSArray *medias = [EWPerson myUnreadMedias];
    
    //fill media from mediaAssets, if no media for task, create a pseudo media
    
    //add Woke media is needed
    if (medias.count == 0) {
        //need to create some voice
        [[EWMediaManager sharedInstance] getWokeVoice];
    }
    
    //save
    [EWSync save];
	
	//set volume
	[[EWAVManager sharedManager] setDeviceVolume:1.0];
    
    //cancel local alarm
    [alarm cancelLocalNotification];
    
    if (isLaunchedFromLocalNotification) {
        //from alarm timer local notification
        DDLogVerbose(@"Entered from local notification, start wakeup view now");
        [[NSNotificationCenter defaultCenter] postNotificationName:kWakeStartNotification object:activity];
        
    }else if (isLaunchedFromRemoteNotification){
        //from push notification
        DDLogVerbose(@"Entered from remote notification, start wakeup view now");
        [[NSNotificationCenter defaultCenter] postNotificationName:kWakeStartNotification object:activity];
        
    }else if (isLaunchedFromAlarmTimer){
        //fire an alarm
        DDLogVerbose(@"=============> Firing Alarm timer notification <===============");
        UILocalNotification *note = [[UILocalNotification alloc] init];
        note.alertBody = [NSString stringWithFormat:@"It's time to wake up (%@)", [alarm.time date2String]];
        note.alertAction = @"Wake up!";
        //alarm.soundName = me.preference[@"DefaultTone"];
        note.userInfo = @{kLocalAlarmID: alarm.objectID.URIRepresentation.absoluteString,
                           kLocalNotificationTypeKey: kLocalNotificationTypeAlarmTimer};
        [[UIApplication sharedApplication] scheduleLocalNotification:note];
        
        //play sound
        [[EWAVManager sharedManager] playSoundFromFileName:[EWPerson me].preference[@"DefaultTone"]];
        
        //play sounds after 30s - time for alarm
        double d = 10;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //present wakeupVC and paly when displayed
			[[EWAVManager sharedManager] volumeTo:0 withCompletion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kWakeStartNotification object:activity];
            }];
        });
    }else{
        //from button pressed
        [[NSNotificationCenter defaultCenter] postNotificationName:kWakeStartNotification object:activity];
    }
}



- (void)sleep:(UILocalNotification *)notification{
    //we use local alarm ID because when scheduling sleep notification, alarm could be be available
    NSString *alarmID = notification.userInfo[kLocalAlarmID];
    if ([EWPerson me]) {
        //logged in enter sleep mode
        EWAlarm *alarm;
        EWActivity *activity = [EWPerson myCurrentAlarmActivity];
        NSNumber *duration = [EWPerson me].preference[kSleepDuration];
        if (alarmID) {
            alarm = [EWAlarm getAlarmByID:alarmID];
            BOOL nextAlarmMatched = [activity.time isEqualToDate:alarm.time.nextOccurTime];
            if (!nextAlarmMatched) {
                DDLogError(@"The sleep notification sent is not the same as the next alarm");
                return;
            }
        }
        
        NSInteger sleepTimeLeft = activity.time.timeIntervalSinceNow/3600;
        BOOL needSleep = sleepTimeLeft < duration.floatValue+5 && sleepTimeLeft > 0;
        if (!needSleep) {
            DDLogWarn(@"Start sleep with %ld hours left", sleepTimeLeft);
        }
        
        //state change
        [EWSession sharedSession].isSleeping = YES;
        [EWSession sharedSession].isWakingUp = NO;
        //send notification so baseNavigationView can present the sleepView
        [[NSNotificationCenter defaultCenter] postNotificationName:kSleepNotification object:notification];
        //mark sleep time on activity
        if (activity.sleepTime) {
            DDLogInfo(@"Back to sleep again. Last sleep time was %@", activity.sleepTime.date2detailDateString);
        }
        activity.sleepTime = [NSDate date];
        [EWSync save];
        
        //start check sleep timer
        //[self alarmTimerCheck];//No need to check, sleepVC will check alarm time
    }
}


//indicate that the user has woke
- (void)wake:(EWActivity *)activity{
    if ([EWSession sharedSession].isWakingUp == NO) {
        DDLogError(@"%s wake up state is NO, skip perform wake action", __FUNCTION__);
        return;
    }
    else if (activity.time.timeIntervalSinceNow > kMaxEalyWakeInterval){
        DDLogWarn(@"Wake too early. Skip ");
        return;
    }
    [EWSession sharedSession].isSleeping = NO;
    [EWSession sharedSession].isWakingUp = NO;
    
    //handle wakeup signel
    [[ATConnect sharedConnection] engage:kWakeupSuccess fromViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
    
    //set wakeup time, move to past, schedule and save
    [[EWActivityManager sharedManager] completeAlarmActivity:[EWPerson myCurrentAlarmActivity]];
    
    //post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kWokeNotification object:nil];
    
    //TODO: something to do in the future
    //notify friends and challengers
    //update history stats
}


#pragma mark - Utility
+ (BOOL)isRootPresentingWakeUpView{
    //determin if WakeUpViewController is presenting
    UIViewController *vc = [UIApplication sharedApplication].delegate.window.rootViewController.presentedViewController;
    if ([NSStringFromClass([vc class]) isEqualToString:@"EWWakeUpViewController"]) {
        return YES;
    }else if ([NSStringFromClass([vc class]) isEqualToString:@"EWPreWakeViewController"]){
        return YES;
    }
    return NO;
}

#pragma mark - CHECK TIMER
- (void) alarmTimerCheck{
    //check time
    if (![EWPerson me]) return;
    EWActivity *activity = [EWPerson myCurrentAlarmActivity];
    
    //alarm time up
    NSTimeInterval timeLeft = [activity.time timeIntervalSinceNow];

	
    static NSTimer *timerScheduled;
    //set up a wake Up Timer
    if (timeLeft > 0 && (!timerScheduled || ![timerScheduled.fireDate isEqualToDate:activity.time])) {
        NSLog(@"About to init alart timer in %fs", timeLeft);
		[timerScheduled invalidate];
		timerScheduled = [NSTimer bk_scheduledTimerWithTimeInterval:timeLeft-1 block:^(NSTimer *timer) {
            NSDictionary *info = @{kActivityLocalID: activity.objectID};
			[[EWWakeUpManager sharedInstance] startToWakeUp:info];
		} repeats:NO];
		NSLog(@"===========================>> Alarm Timer scheduled on %@) <<=============================", activity.time.date2String);
    }
	//schedule next check
	if (timeLeft > kServerUpdateInterval) {
		[NSTimer scheduledTimerWithTimeInterval:timeLeft/2 target:self selector:@selector(alarmTimerCheck) userInfo:nil repeats:NO];
		DDLogVerbose(@"Next alarm timer check in %.1fs", timeLeft/2);
	}
}

- (void)sleepTimerCheck{
    //check time
    if (![EWPerson me]) return;
    EWActivity *activity = [EWPerson myCurrentAlarmActivity];
    
    //alarm time up
    NSNumber *sleepDuration = [EWPerson me].preference[kSleepDuration];
    NSInteger durationInSeconds = sleepDuration.integerValue * 3600;
    NSDate *sleepTime = [activity.time dateByAddingTimeInterval:-durationInSeconds];
	NSTimeInterval timeLeft = sleepTime.timeIntervalSinceNow;
    static NSTimer *timerScheduled;
    
    //if there is time left and the sleepTimer is either not set up or the sleepTimer is not correct, reschedule a sleepTimer
    if (timeLeft > 0 && (!timerScheduled || ![timerScheduled.fireDate isEqualToDate:sleepTime])) {
        DDLogVerbose(@"About to init alarm timer in %fs", timeLeft);
		[timerScheduled invalidate];
		timerScheduled = [NSTimer bk_scheduledTimerWithTimeInterval:timeLeft-1 block:^(NSTimer *timer) {
			[[EWWakeUpManager sharedInstance] sleep:nil];
		} repeats:NO];
		DDLogVerbose(@"===========================>> Sleep Timer scheduled on %@ <<=============================", sleepTime.date2String);
    }
    
    //schedule next sleep timer check if the time left is larger than 5mim
    if (timeLeft > 300) {
        [NSTimer scheduledTimerWithTimeInterval:timeLeft/2 target:self selector:@selector(sleepTimerCheck) userInfo:nil repeats:NO];
        DDLogVerbose(@"Next alarm timer check in %.1fs", timeLeft);
    }
}

#pragma mark - Play for wake up view
- (void)playNextVoiceWithPause{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMediaPlayInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //check if playing media is changed
        if (self.currentMedia != [EWAVManager sharedManager].media) {
            DDLogInfo(@"Media has changed since during the delay. Skip!");
            return;
        }
        [self playNextVoice];
    });
}

- (void)playNextVoice{
    
    //Active session
    [[EWAVManager sharedManager] registerActiveAudioSession];
    
    //check if need to play next
    if (!self.continuePlay){
        DDLogInfo(@"Next is disabled, stop playing next");
        return;
    }
    //return if no  medias
    if (!_medias.count) {
        DDLogWarn(@"%s No media to play", __FUNCTION__);
        return;
    }
    
    NSUInteger mediaJustPlayedIdx = [_medias indexOfObject:self.currentMedia];//if not found, next = 0
    if (mediaJustPlayedIdx == NSNotFound) {
        mediaJustPlayedIdx = 0;
    } else {
        mediaJustPlayedIdx ++;
    }
    
    if (mediaJustPlayedIdx < _medias.count){
        //get next cell
        NSLog(@"Play next song (%ld)", (long)mediaJustPlayedIdx);
        self.currentMedia = _medias[mediaJustPlayedIdx];
        [[EWAVManager sharedManager] playMedia:_currentMedia];
        
    }else{
        if ((--_loopCount)>0) {
            //play the first if loopCount > 0
            NSLog(@"Looping, %ld loop left", (long)_loopCount);
            self.currentMedia = _medias.firstObject;
            [[EWAVManager sharedManager] playMedia:_currentMedia];
            
        }else{
            NSLog(@"Loop finished, stop playing");
            //nullify all info in EWAVManager
            [self stopPlayingVoice];
            self.currentMedia = nil;
            return;
        }
    }
}

- (void)stopPlayingVoice{
    [[EWAVManager sharedManager] stopAllPlaying];
}

- (void)playVoiceAtIndex:(NSUInteger)n{
    self.currentMedia = _medias[n];
    [[EWAVManager sharedManager] playMedia:_medias[n]];
}

- (NSUInteger)currentMediaIndex{
    return [_medias indexOfObjectIdenticalTo:_currentMedia];
}

- (void)reloadMedias{
	BOOL forceLoad = NO;
#ifdef DEBUG
	forceLoad = YES;
#endif
	
    if ([EWSession sharedSession].isWakingUp || forceLoad) {
        self.medias = [EWPerson myUnreadMedias];
    }else{
        DDLogVerbose(@"Current seesion is not in wakingUp mode, playing media list will not load from myUnreadMedias");
    }
}
@end
