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

NSString * const kAlarmTimerDidFireNotification = @"kAlarmTimerDidFireNotification";
NSString * const kEWWakeUpDidPlayNextMediaNotification = @"kEWWakeUpDidPlayNextMediaNotification";
NSString * const kEWWakeUpDidStopPlayMediaNotification = @"kEWWakeUpDidStopPlayMediaNotification";

@interface EWWakeUpManager ()
@property (nonatomic, strong) NSTimer *alarmTimer;
@end
@implementation EWWakeUpManager

+ (EWWakeUpManager *)sharedInstance{
    static EWWakeUpManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWWakeUpManager alloc] init];
        manager.delegate = [EWActivityManager sharedManager];
    });
    return manager;
}

- (id)init{
	self = [super init];
    [self reloadMedias];
    
    self.continuePlay = YES;
	[[NSNotificationCenter defaultCenter] addObserverForName:kBackgroundingStartNotice object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self scheduleAlarmTimer];
		[self sleepTimerCheck];
	}];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextVoiceWithDelay) name:kAVManagerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMedias) name:kNewMediaNotification object:nil];
    
    //first time loop
    self.loopCount = kLoopMediaPlayCount;
    
	return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Handle events
- (void)startToWakeUpWithAlarm:(EWAlarm *)alarm {
    EWAssertMainThread
    if (![self.delegate wakeupManager:self shouldWakeUpWithAlarm:alarm]) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(wakeUpManagerWillWakeUp:)]) {
        [self.delegate wakeUpManagerWillWakeUp:self];
    }
    
    DDLogInfo(@"Start handle timer event");
    //state change
    [EWSession sharedSession].wakeupStatus = EWWakeUpStatusWakingUp;
    
    //update media
    [[EWMediaManager sharedInstance] checkUnreadMedias];
    self.medias = [EWPerson myUnreadMedias];
    
    //fill media from mediaAssets, if no media for task, create a pseudo media
    
    //add Woke media is needed
    if (self.medias.count == 0) {
        //need to create some voice
        [[EWMediaManager sharedInstance] getWokeVoice];
    }
    
    //set volume
    [[EWAVManager sharedManager] setDeviceVolume:1.0];
    
    //cancel local alarm
    [alarm cancelLocalNotification];
    
    if ([self.delegate respondsToSelector:@selector(wakeUpManagerDidWakeUp:)]) {
        [self.delegate wakeUpManagerDidWakeUp:self];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWakeStartNotification object:nil];
}

- (void)startToWakeUp {
    [self startToWakeUpWithAlarm:[EWPerson myCurrentAlarm]];
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
        [EWSession sharedSession].wakeupStatus = EWWakeUpStatusSleeping;
        //send notification so baseNavigationView can present the sleepView
        [[NSNotificationCenter defaultCenter] postNotificationName:kSleepNotification object:notification];
        //mark sleep time on activity
        if (activity.sleepTime) {
            DDLogInfo(@"Back to sleep again. Last sleep time was %@", activity.sleepTime.date2detailDateString);
        }
        activity.sleepTime = [NSDate date];
        [activity save];
        
        //start check sleep timer
        //[self alarmTimerCheck];//No need to check, sleepVC will check alarm time
    }
}


//indicate that the user has woke
- (void)wake:(EWActivity *)activity{
    if ([EWSession sharedSession].wakeupStatus != EWWakeUpStatusWakingUp) {
        DDLogError(@"%s wake up state is NO, skip perform wake action", __FUNCTION__);
        return;
    }
    else if (activity.time.timeIntervalSinceNow > kMaxEalyWakeInterval){
        DDLogWarn(@"Wake too early. Skip ");
        return;
    }
    [EWSession sharedSession].wakeupStatus = EWWakeUpStatusWoke;
    
    //handle wakeup signel
    [[ATConnect sharedConnection] engage:kWakeupSuccess fromViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
    
    //set wakeup time, move to past, schedule and save
    [[EWActivityManager sharedManager] completeAlarmActivity:activity];
    
    //post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kWokeNotification object:nil];
    
    //THOUGHTS: something to do in the future
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
- (void)scheduleAlarmTimer {
    if (![EWPerson me]) return;
    EWActivity *activity = [EWPerson myCurrentAlarmActivity];
    
    //alarm time up
	NSTimeInterval timeLeft = activity.time.timeIntervalSinceNow;
    
    [self.alarmTimer invalidate];
    
    self.alarmTimer = [NSTimer bk_timerWithTimeInterval:timeLeft block:^(NSTimer *timer) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmTimerDidFireNotification object:nil];
    } repeats:NO];
}

- (void)alarmTimerCheck{
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
            [[EWWakeUpManager sharedInstance] startToWakeUp];
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
- (void)playNextVoiceWithDelay {
    EWMedia *currentMediaBackup = self.currentMedia;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMediaPlayInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //check if playing media is changed
        if (self.currentMedia != currentMediaBackup && [EWAVManager sharedManager].player.isPlaying) {
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
    
    if (self.currentMediaIndex < _medias.count - 1){
        //get next cell
        DDLogInfo(@"Play next song (%@)", @(self.currentMediaIndex));
        [[EWAVManager sharedManager] playMedia:self.currentMedia];
        self.currentMediaIndex++;
        [[NSNotificationCenter defaultCenter] postNotificationName:kEWWakeUpDidPlayNextMediaNotification object:nil];
    }
    else if (self.currentMediaIndex == _medias.count - 1) {
        [[EWAVManager sharedManager] playMedia:self.currentMedia];
        [[NSNotificationCenter defaultCenter] postNotificationName:kEWWakeUpDidPlayNextMediaNotification object:nil];
    }
    else { //index == _medias.count
        if ((self.loopCount)>0) {
            //play the first if loopCount > 0
            DDLogInfo(@"Looping, %ld loop left", (long)_loopCount);
            self.loopCount++;
            self.currentMediaIndex = 0;
            [[EWAVManager sharedManager] playMedia:self.currentMedia];
            [[NSNotificationCenter defaultCenter] postNotificationName:kEWWakeUpDidPlayNextMediaNotification object:nil];
        }
        else{
            DDLogInfo(@"Loop finished, stop playing");
            //nullify all info in EWAVManager
            [self stopPlayingVoice];
            return;
        }
    }
}

- (void)stopPlayingVoice {
    [[EWAVManager sharedManager] stopAllPlaying];
    [[NSNotificationCenter defaultCenter] postNotificationName:kEWWakeUpDidStopPlayMediaNotification object:nil];
}

- (void)playMediaAtIndex:(NSUInteger)index {
    self.currentMediaIndex = index;
    [[EWAVManager sharedManager] playMedia:self.currentMedia];
}

- (void)playMedia:(EWMedia *)media {
    NSUInteger index = [self.medias indexOfObject:media];
    if (index == NSNotFound) {
        DDLogError(@"Media not found");
        NSAssert(false, @"Media not found");
    }
    [self playMediaAtIndex:index];
}

- (void)reloadMedias{
	BOOL forceLoad = NO;
#ifdef DEBUG
	forceLoad = YES;
#endif
	
    if ([EWSession sharedSession].wakeupStatus == EWWakeUpStatusWakingUp || forceLoad) {
        self.medias = [EWPerson myUnreadMedias];
    }else{
        DDLogVerbose(@"Current seesion is not in wakingUp mode, playing media list will not load from myUnreadMedias");
    }
}

- (EWMedia *)currentMedia {
    if (_currentMediaIndex >= self.medias.count) {
        DDLogError(@"currentMedia index overflow");
        return nil;
    }
    return self.medias[_currentMediaIndex];
}
@end
