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
//#import "AppDelegate.h"

//UI
#import "EWWakeUpViewController.h"
#import "EWPostWakeUpViewController.h"
//#import "EWSleepViewController.h"
//#import "EWPostWakeUpViewController.h"
//#import "UIView+Extend.h"
//#import "UIView+Blur.h"
//#import "UIViewController+Blur.h"


@interface EWWakeUpManager()
//retain the controller so that it won't deallocate when needed
//@property (nonatomic, retain) EWWakeUpViewController *controller;
@end


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
    _alarm = [EWPerson myCurrentAlarm];
	[[NSNotificationCenter defaultCenter] addObserverForName:kBackgroundingEnterNotice object:nil queue:nil usingBlock:^(NSNotification *note) {
		[self alarmTimerCheck];
		[self sleepTimerCheck];
	}];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextVoice) name:kAudioPlayerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kNewMediaNotification object:nil];
    
	return self;
}

- (EWAlarm *)alarm{
    return [EWPerson myCurrentAlarm];
}

#pragma mark - Handle push notification
- (void)handlePushMedia:(NSDictionary *)notification{
    NSString *pushType = notification[kPushType];
    NSParameterAssert([pushType isEqualToString:kPushTypeMedia]);
    NSString *type = notification[kPushMediaType];
    NSString *mediaID = notification[kPushMediaID];
    EWActivity *activity = [[EWActivityManager sharedManager] currentAlarmActivity];
	
    if (!mediaID) {
        NSLog(@"Push doesn't have media ID, abort!");
        return;
    }
    
    EWMedia *media = [EWMedia getMediaByID:mediaID];
    //NSDate *nextTimer = nextAlarm.time;
    
    if ([type isEqualToString:kPushMediaTypeVoice]) {
        // ============== Media ================
        NSParameterAssert(mediaID);
        NSLog(@"Received voice type push");
        
        
        //determin action based on task timing
        if ([[NSDate date] isEarlierThan:activity.time]) {
            
            //============== pre alarm -> download ==============
            
        }else if (!activity.completed && [[NSDate date] timeIntervalSinceDate:activity.time] < kMaxWakeTime){
            
            //============== struggle ==============
            
            //assign activity
            media.activity = activity;
            
            //broadcast so wakeupVC can react to it
            //Wait until the media has been downloaded
            //[[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:self userInfo:activity];
            
            //save
            [EWSync save];
            
        }else{
            
            //Woke state -> assign media to next task, download
            if (![[EWPerson me].unreadMedias containsObject:media]) {
                [[EWPerson me] addUnreadMediasObject:media];
                [EWSync save];
                
            }
            
        }
        
#ifdef DEBUG
        [[[UIAlertView alloc] initWithTitle:@"Voice来啦" message:@"收到一条神秘的语音."  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#endif
        
        
    }else if([type isEqualToString:@"test"]){
        
        // ============== Test ================
        
        NSLog(@"Received === test === type push");
        [UIApplication sharedApplication].applicationIconBadgeNumber = 9;
        
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
    NSArray *medias = [EWPerson me].unreadMedias.allObjects;
    
    //fill media from mediaAssets, if no media for task, create a pseudo media
    NSInteger nVoiceNeeded = 1;
    
    for (EWMedia *media in medias) {
        if (!media.targetDate || [media.targetDate timeIntervalSinceNow]<0) {
            
            //find media to add
            [activity addMediasObject: media];
            //remove media from mediaAssets, need to remove relation doesn't have inverse relation. This is to make sure the sender doesn't need to modify other person
            [[EWPerson me] removeUnreadMediasObject:media];
            //!!!single directional relation? Remove media.receiver?
            
            //stop if enough
            if ([media.type isEqualToString: kMediaTypeVoice]) {
                //reduce the counter
                nVoiceNeeded--;
                if (nVoiceNeeded <= 0) {
                    break;
                }
            }
        }
    }
    
    //add Woke media is needed
    if ([EWPerson myUnreadMedias].count == 0) {
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
        [[NSNotificationCenter defaultCenter] postNotificationName:kWakeTimeNotification object:activity];
        
    }else if (isLaunchedFromRemoteNotification){
        
        NSLog(@"Entered from remote notification, start wakeup view now");
        [[NSNotificationCenter defaultCenter] postNotificationName:kWakeTimeNotification object:activity];
        
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
                [[NSNotificationCenter defaultCenter] postNotificationName:kWakeTimeNotification object:activity];
            }];
        });
    }
}

#pragma mark - Utility
+ (BOOL)isRootPresentingWakeUpView{
    //determin if WakeUpViewController is presenting
    UIViewController *vc = [UIApplication sharedApplication].delegate.window.rootViewController.presentedViewController;
    if ([vc isKindOfClass:[EWWakeUpViewController class]]) {
        return YES;
    }else if ([vc isKindOfClass:[EWPostWakeUpViewController class]]){
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
- (void)playNextVoice{
    EWMedia *mediaJustFinished = mediaJustFinished = [EWAVManager sharedManager].media;
    float t = 0;
    if (mediaJustFinished) {
        t = kMediaPlayInterval;
    }
    //delay 3s if there is a media playing previously
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(t * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //check if playing media is changed
        if (mediaJustFinished != [EWAVManager sharedManager].media) {
            DDLogInfo(@"Media has changed since during the delay. Skip!");
            return;
        }
        
        //check if need to play next
        if (!self.playNext){
            DDLogInfo(@"Next is disabled, stop playing next");
            return;
        }
        //return if no  medias
        if (!_medias.count) {
            return;
        }
        
        NSUInteger mediaJustPlayed = [_medias indexOfObject:mediaJustFinished];//if not found, next = 0
        if (mediaJustPlayed != _currentMediaIndex) {
            DDLogInfo(@"Media order has changed since last known. Skip!");
            return;
        }
        _currentMediaIndex ++;
        
        if (_currentMediaIndex < _medias.count){
            //get next cell
            NSLog(@"Play next song (%ld)", (long)_currentMediaIndex);
            [[EWAVManager sharedManager] playMedia:_medias[_currentMediaIndex]];
            
        }else{
            if ((--_loopCount)>0) {
                //play the first if loopCount > 0
                NSLog(@"Looping, %ld loop left", (long)_loopCount);
                [[EWAVManager sharedManager] playMedia:_medias.firstObject];
                
            }else{
                NSLog(@"Loop finished, stop playing");
                //nullify all cell info in EWAVManager
                self.currentMediaIndex = 0;
                
                [EWAVManager sharedManager].media = nil;
                return;
            }
        }
    });
}

- (void)stopPlayingVoice{
    [[EWAVManager sharedManager] stopAllPlaying];
}

- (float)playingProgress{
    float t = [EWAVManager sharedManager].player.currentTime;
    float T = [EWAVManager sharedManager].player.duration;
    return t/T;
}

- (void)playVoiceAtIndex:(NSUInteger)n{
    [[EWAVManager sharedManager] playMedia:_medias[n]];
}

- (EWPerson *)currentWaker{
    EWMedia *mediaPlaying = _medias[_currentMediaIndex];
    return mediaPlaying.author;
}

@end
