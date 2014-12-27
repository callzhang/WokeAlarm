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
    self.alarm = [EWPerson myCurrentAlarm];
    self.medias = [EWPerson myUnreadMedias];
    self.continuePlay = YES;
	[[NSNotificationCenter defaultCenter] addObserverForName:kBackgroundingEnterNotice object:nil queue:nil usingBlock:^(NSNotification *note) {
		[self alarmTimerCheck];
		[self sleepTimerCheck];
	}];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextVoiceWithPause) name:kAVManagerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] addObserverForName:kNewMediaNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.medias = [EWPerson myUnreadMedias];
    }];
	return self;
}

#pragma mark - Handle push notification
- (void)handlePushMedia:(NSDictionary *)notification{
    NSString *pushType = notification[kPushType];
    NSParameterAssert([pushType isEqualToString:kPushTypeMedia]);
    NSString *type = notification[kPushMediaType];
    NSString *mediaID = notification[kPushMediaID];
	
    if (!mediaID) {
        NSLog(@"Push doesn't have media ID, abort!");
        return;
    }
    
    //download media
    EWMedia *media = [EWMedia getMediaByID:mediaID];
    //Woke state -> assign media to next task, download
    if (![[EWPerson me].unreadMedias containsObject:media]) {
        [[EWPerson me] addUnreadMediasObject:media];
        [EWSync save];
        
    }
    
    if ([type isEqualToString:kPushMediaTypeVoice]) {
        // ============== Media ================
        NSParameterAssert(mediaID);
        NSLog(@"Received voice type push");
        
#ifdef DEBUG
        [[[UIAlertView alloc] initWithTitle:@"Voice来啦" message:@"收到一条神秘的语音."  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#endif
        
    }else if([type isEqualToString:@"test"]){
        
        // ============== Test ================
        
        DDLogInfo(@"Received === test === type push");
        EWAlert(@"Received === test === type push");
        [UIApplication sharedApplication].applicationIconBadgeNumber = 99;
    }
}

- (void)handleAlarmTimerEvent:(NSDictionary *)info{
    NSParameterAssert([NSThread isMainThread]);
    if ([EWSession sharedSession].isWakingUp) {
        DDLogWarn(@"WakeUpManager is already handling alarm timer, skip");
        return;
    }else if ([EWWakeUpManager isRootPresentingWakeUpView]) {
		DDLogWarn(@"WakeUpView is already presented, skip");
		return;
	}
    
    BOOL isLaunchedFromLocalNotification = NO;
    BOOL isLaunchedFromRemoteNotification = NO;
	
    //get target activity
    EWAlarm *alarm;
    EWActivity *activity = [EWActivityManager sharedManager].currentAlarmActivity;
    if (info) {
        NSString *alarmID = info[kPushAlarmID];
        NSString *alarmLocalID = info[kLocalAlarmID];
        NSParameterAssert(alarmID || alarmLocalID);
        if (alarmID) {
            isLaunchedFromRemoteNotification = YES;
            alarm = [EWAlarm getAlarmByID:alarmID];
        }else if (alarmLocalID){
            isLaunchedFromLocalNotification = YES;
            NSURL *url = [NSURL URLWithString:alarmLocalID];
            NSManagedObjectID *ID = [mainContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
            if (ID) {
                alarm = (EWAlarm *)[mainContext existingObjectWithID:ID error:NULL];
            }else{
                DDLogError(@"The task objectID is invalid for alarm timer local notif: %@",alarmLocalID);
            }
        }
		
	}else{
		alarm = [EWPerson myCurrentAlarm];
	}
	
	
    NSLog(@"Start handle timer event");
    if (!alarm) {
        DDLogError(@"*** %s No alarm found for next alarm, abord", __func__);
        return;
    }
    
    if (alarm.state == NO) {
        NSLog(@"Alarm is OFF, skip today's alarm");
        return;
    }
    if (alarm.time.nextOccurTime.timeElapsed > kMaxWakeTime) {
        NSLog(@"Activity(%@) from notification has passed the wake up window. Handle it with checkPastTasks.", activity.objectId);
        [[EWActivityManager sharedManager] currentAlarmActivity];
        return;
    }
    
    if (activity.completed) {
        // task completed
        NSLog(@"Activity has completed at %@, skip.", activity.completed.date2String);
        return;
    }

    //state change
    [EWSession sharedSession].isSleeping = NO;
    [EWSession sharedSession].isWakingUp = YES;
    
    //update media
    [[EWMediaManager sharedInstance] checkMediaAssets];
    NSArray *medias = [EWPerson myUnreadMedias];
    
    //fill media from mediaAssets, if no media for task, create a pseudo media
    //NSInteger nVoiceNeeded = 1;
    
    //add Woke media is needed
    if (medias.count == 0) {
        //need to create some voice
        EWMedia *media = [[EWMediaManager sharedInstance] getWokeVoice];
        [[EWPerson me] addUnreadMediasObject:media];
    }
    
    //save
    [EWSync save];
	
	//set volume
	[[EWAVManager sharedManager] setDeviceVolume:1.0];
    
    //cancel local alarm
    [alarm cancelLocalNotification];
    
    if (isLaunchedFromLocalNotification) {
        
        NSLog(@"Entered from local notification, start wakeup view now");
        [[NSNotificationCenter defaultCenter] postNotificationName:kWakeStartNotification object:activity];
        
    }else if (isLaunchedFromRemoteNotification){
        
        NSLog(@"Entered from remote notification, start wakeup view now");
        [[NSNotificationCenter defaultCenter] postNotificationName:kWakeStartNotification object:activity];
        
    }else{
        //fire an alarm
        NSLog(@"=============> Firing Alarm timer notification <===============");
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
#ifdef DEBUG
        d = 5;
#endif
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //present wakeupVC and paly when displayed
            [[EWAVManager sharedManager] volumeFadeWithCompletion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kWakeStartNotification object:activity];
            }];
        });
    }
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

#pragma mark - Actions

//indicate that the user has woke
- (void)wake{
    
    [EWSession sharedSession].isSleeping = NO;
    [EWSession sharedSession].isWakingUp = NO;
    
    //handle wakeup signel
    [[ATConnect sharedConnection] engage:kWakeupSuccess fromViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
    
    //set wakeup time, move to past, schedule and save
    [[EWActivityManager sharedManager] completeAlarmActivity:[EWPerson myCurrentAlarmActivity]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWokeNotification object:nil];
    
    //TODO: something to do in the future
    //notify friends and challengers
    //update history stats
}

- (void)sleep{
    //check that current alarm activity and alarm are correct
    [self alarmTimerCheck];
    [EWSession sharedSession].isSleeping = YES;
}

#pragma mark - CHECK TIMER
- (void) alarmTimerCheck{
    //check time
    if (![EWPerson me]) return;
    EWAlarm *alarm = [EWPerson myCurrentAlarm];
    if (alarm.state == NO) return;
    
    //alarm time up
    NSTimeInterval timeLeft = [alarm.time timeIntervalSinceNow];

	
    static NSTimer *timerScheduled;
    if (timeLeft > 0 && (!timerScheduled || ![timerScheduled.fireDate isEqualToDate:alarm.time])) {
        NSLog(@"%s: About to init alart timer in %fs", __func__, timeLeft);
		[timerScheduled invalidate];
		[NSTimer bk_scheduledTimerWithTimeInterval:timeLeft-1 block:^(NSTimer *timer) {
			[[EWWakeUpManager sharedInstance] handleAlarmTimerEvent:nil];
		} repeats:NO];
		NSLog(@"===========================>> Alarm Timer scheduled on %@) <<=============================", alarm.time.date2String);
    }
	
	if (timeLeft > kServerUpdateInterval) {
		[NSTimer scheduledTimerWithTimeInterval:timeLeft/2 target:self selector:@selector(alarmTimerCheck) userInfo:nil repeats:NO];
		DDLogVerbose(@"Next alarm timer check in %.1fs", timeLeft/2);
	}
}

- (void)sleepTimerCheck{
    //check time
    if (![EWPerson me]) return;
    EWAlarm *alarm = [EWPerson myCurrentAlarm];
    if (alarm.state == NO) return;
    
    //alarm time up
    NSNumber *sleepDuration = [EWPerson me].preference[kSleepDuration];
    NSInteger durationInSeconds = sleepDuration.integerValue * 3600;
    NSDate *sleepTime = [alarm.time dateByAddingTimeInterval:-durationInSeconds];
	NSTimeInterval timeLeft = sleepTime.timeIntervalSinceNow;
    static NSTimer *timerScheduled;
    if (timeLeft > 0 && (!timerScheduled || ![timerScheduled.fireDate isEqualToDate:sleepTime])) {
        NSLog(@"%s: About to init alart timer in %fs", __func__, timeLeft);
		[timerScheduled invalidate];
		timerScheduled = [NSTimer bk_scheduledTimerWithTimeInterval:timeLeft-1 block:^(NSTimer *timer) {
			[[EWWakeUpManager sharedInstance] handleSleepTimerEvent:nil];
		} repeats:NO];
		NSLog(@"===========================>> Sleep Timer scheduled on %@ <<=============================", sleepTime.date2String);
    }
	
	if (timeLeft > 300) {
		[NSTimer scheduledTimerWithTimeInterval:timeLeft/2 target:self selector:@selector(alarmTimerCheck) userInfo:nil repeats:NO];
		DDLogVerbose(@"Next alarm timer check in %.1fs", timeLeft);
	}
}

- (void)handleSleepTimerEvent:(UILocalNotification *)notification{
    NSString *alarmID = notification.userInfo[kLocalAlarmID];
    if ([EWPerson me]) {
        //logged in enter sleep mode
        EWAlarm *alarm = [EWPerson myCurrentAlarm];
        NSNumber *duration = [EWPerson me].preference[kSleepDuration];
        if (alarmID) {
            BOOL nextAlarmMatched = [alarm.objectID.URIRepresentation.absoluteString isEqualToString:alarmID];
            if (!nextAlarmMatched) {
                DDLogError(@"The sleep notification sent is not the same as the next alarm");
                return;
            }
        }
        
        NSInteger h = alarm.time.timeIntervalSinceNow/3600;
        BOOL needSleep = h < duration.floatValue && h > 1;
        
        if (needSleep) {
            //send notification so baseNavigationView can present the sleepView
            [[NSNotificationCenter defaultCenter] postNotificationName:kSleepTimeNotification object:alarm];
        }
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
        DDLogWarn(@"[%s] No media to play", __FUNCTION__);
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

@end
