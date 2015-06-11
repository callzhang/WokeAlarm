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
#import "EWAlarm.h"
#import "EWActivity.h"
#import "EWActivityManager.h"
#import "EWAlarmManager.h"
#import "NSTimer+BlocksKit.h"

#import "EWUIUtil.h"
#import "EWBackgroundingManager.h"


FBTweakAction(@"WakeUpManager", @"Action", @"Wake Up in 30s", ^{
    [[EWWakeUpManager shared] testWakeUpInSeconds:30];
});

FBTweakAction(@"WakeUpManager", @"Action", @"Wake Up in 10s", ^{
    [[EWWakeUpManager shared] testWakeUpInSeconds:10];
});

FBTweakAction(@"WakeUpManager", @"Action", @"Remove future activities' completion date", ^{
    NSArray *futureActivities = [EWActivity MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"%K = %@ AND %K > %@ AND %K != nil", EWActivityRelationships.owner, [EWPerson me], EWActivityAttributes.time, [NSDate date], EWActivityAttributes.completed] inContext:mainContext];
    for(EWActivity *activity in futureActivities){
        DDLogDebug(@"Activity's completion time %@ removed", activity.completed.string);
        activity.completed = nil;
        [activity save];
    }
});

FBTweakAction(@"WakeUpManager", @"Action", @"Remove unread medias", ^{
	NSArray *unread = [EWPerson myUnreadMedias];
	for (EWMedia *media in unread) {
		DDLogDebug(@"Removed EWMedia PO %@", media.serverID);
		[[EWPerson me] removeReceivedMediasObject:media];
	}
});

FBTweakAction(@"WakeUpManager", @"Action", @"Unread medias count", ^{
	NSArray *unread = [EWPerson myUnreadMedias];
	NSString *str = [NSString stringWithFormat:@"Unread medias: %lu", (unsigned long)unread.count];
	EWAlert(str);
});

NSString * const kAlarmTimerDidFireNotification = @"kAlarmTimerDidFireNotification";
NSString * const kEWWakeUpDidPlayNextMediaNotification = @"kEWWakeUpDidPlayNextMediaNotification";
NSString * const kEWWakeUpDidStopPlayMediaNotification = @"kEWWakeUpDidStopPlayMediaNotification";

@interface EWWakeUpManager ()
@property (nonatomic, strong) NSTimer *alarmTimer;
@property (nonatomic, strong) EWActivity *tempActivity;
@end
@implementation EWWakeUpManager

GCD_SYNTHESIZE_SINGLETON_FOR_CLASS(EWWakeUpManager)

- (id)init{
	self = [super init];
    self.delegate = [EWActivityManager sharedManager];
    
    //[self reloadMedias];
    
    self.continuePlay = YES;
	[[NSNotificationCenter defaultCenter] addObserverForName:kBackgroundingStartNotice object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self scheduleAlarmTimer];
		//[self sleepTimerCheck];
	}];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextVoiceWithDelay) name:kAVManagerDidFinishPlaying object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserverForName:kAVManagerDidStartPlaying object:nil queue:nil usingBlock:^(NSNotification *note) {
        if ([note.object isKindOfClass:[EWMedia class]]) {
            EWMedia *m = (EWMedia *)note.object;
            if (!m.played) {
                //prevent exccessive saving and uploading
                m.played = [NSDate date];
                [m save];
                DDLogVerbose(@"EWMedia %@ set played time to %@", m.serverID, m.played.date2String);
            }
        }
    }];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadUnreadMedias) name:kNewMediaNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scheduleAlarmTimer) name:kAlarmTimeChanged object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scheduleAlarmTimer) name:kAlarmStateChanged object:nil];
	
    //first time loop
    FBTweakBind(self, loopCount, @"WakeUpManager", @"Play", @"loop count", 100);
	FBTweakBind(self, forceSleep, @"WakeUpManager", @"Wake", @"Enable force sleep", NO);
	FBTweakBind(self, forceWakeUp, @"WakeUpManager", @"Wake", @"Enable force wake up", NO);
	FBTweakBind(self, forceSnooze, @"WakeUpManager", @"Wake", @"Enable snooze", NO);
	FBTweakBind(self, skipCheckActivityCompleted, @"WakeUpManager", @"Wake", @"Skip check activity completed", NO);
    
	return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Handle events
- (void)startToWakeUp {
    [self startToWakeUpWithAlarm:[EWPerson myCurrentAlarm]];
}

- (void)startToWakeUpWithAlarm:(EWAlarm *)alarm {
    EWAssertMainThread
    NSParameterAssert(self.delegate);
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
    self.medias = [EWPerson myUnreadMedias];
    
    //add Woke media is needed
    if (self.medias.count == 0) {
        //need to create some voice in sync
        EWMedia *newMedia = [[EWMediaManager sharedInstance] getWokeVoice];
		if (newMedia) {
			self.medias = @[newMedia];
		} else {
			//TODO add a local fallback voice
		}
    }
    
    //cancel local alarm
    [alarm cancelLocalNotification];
    
    //cancel alarm timer
    [self.alarmTimer invalidate];
    
    
    if ([self.delegate respondsToSelector:@selector(wakeUpManagerDidWakeUp:)]) {
        [self.delegate wakeUpManagerDidWakeUp:self];
    }
    
    //start to play
    [self startToPlayVoice];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWakeStartNotification object:nil];
    
    self.continuePlay = YES;
}

- (void)sleep:(NSDictionary *)userInfo{
    //we use local alarm ID because when scheduling sleep notification, alarm could be be available
    if (![EWPerson me]) return;
    NSString *alarmID = userInfo[kLocalAlarmID];
    //logged in enter sleep mode
    EWAlarm *alarm;
    EWActivity *activity = [EWPerson myCurrentAlarmActivity];
    if (alarmID) {
        alarm = [EWAlarm getAlarmByID:alarmID error:nil];
        BOOL nextAlarmMatched = [activity.time isEqualToDate:alarm.time.nextOccurTime];
        if (!nextAlarmMatched) {
            DDLogError(@"The sleep notification sent is not the same as the next alarm, skip sleep");
            return;
        }
    }
    
    //max sleep 5 hours early
    BOOL canSleep = [self shouldSleep];
    if (!canSleep) {
        return;
    }
    
    //state change
    [EWSession sharedSession].wakeupStatus = EWWakeUpStatusSleeping;
    //send notification so baseNavigationView can present the sleepView
    [[NSNotificationCenter defaultCenter] postNotificationName:kSleepNotification object:userInfo];
    //mark sleep time on activity
    if (activity.sleepTime) {
        DDLogInfo(@"Back to sleep again. Last sleep time was %@", activity.sleepTime.date2detailDateString);
    }
    //if there is medias in activity, remove it
    if (activity.mediaIDs.count) {
        DDLogWarn(@"Activity already has medias: %@", activity.mediaIDs);
        [activity.mediaIDs removeAllObjects];
    }
    activity.sleepTime = [NSDate date];
    [activity save];
    
    //reset the test status
    //self.forceSnooze = NO;
    //self.forceWakeUp = NO;
}

- (void)unsleep{
    EWActivity *activity = [EWPerson myCurrentAlarmActivity];
    if (activity.completed) {
        DDLogWarn(@"Already completed wake up, nothing to unsleep");
        return;
    }
    if (!activity.sleepTime) {
        DDLogError(@"No sleep time recorded, hanging in the sleep view too long?");
        return;
    }
    
    activity.sleepTime = nil;
    [activity save];
    
    [EWSession sharedSession].wakeupStatus = EWWakeUpStatusWoke;
}

- (BOOL)shouldSleep{
	float sleepTimeLeft = [self hoursLeftToSleep];
	//max sleep 5 hours early
	BOOL canSleep = sleepTimeLeft < kMaxEarlySleepHours;
	if (!canSleep) {
		if (self.forceSleep) {
			canSleep = YES;
			DDLogInfo(@"Forced enable sleep with %.1f hours advance", sleepTimeLeft);
		} else {
			DDLogWarn(@"Should not sleep with %.1f hours advance", sleepTimeLeft);
		}
	}
	return canSleep;
}

- (float)hoursLeftToSleep{
    NSNumber *duration = [EWPerson me].preference[kSleepDuration];
    EWActivity *activity = [EWPerson myCurrentAlarmActivity];
    float sleepTimeLeft = activity.time.timeIntervalSinceNow/3600;
    sleepTimeLeft -= duration.floatValue;
    return sleepTimeLeft;
}

- (BOOL)canSnooze{
    BOOL can = _forceSnooze && [self shouldSleep];
    return can;
}

- (BOOL)canStartToWakeUp{
    return [self.delegate wakeupManager:self shouldWakeUpWithAlarm:[EWPerson myCurrentAlarm]];
}

//indicate that the user has woke
- (void)wake:(EWActivity *)activity{
    if (!activity) {
        activity = [[EWActivityManager sharedManager] currentAlarmActivity];
    }
    if ([EWSession sharedSession].wakeupStatus != EWWakeUpStatusWakingUp) {
        DDLogError(@"%s wake up state is NOT wakingUp, skip perform wake action", __FUNCTION__);
        return;
    }
    
    [EWSession sharedSession].wakeupStatus = EWWakeUpStatusWoke;
    
    //handle wakeup signel
    [[ATConnect sharedConnection] engage:kWakeupSuccess fromViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
    
    //set wakeup time, move to past, schedule and save
    [[EWActivityManager sharedManager] completeAlarmActivity:activity];
    
    //playing states
    self.continuePlay = NO;
    self.medias = nil;
    self.currentMediaIndex = nil;
    self.skipCheckActivityCompleted = NO;
    
    //post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kWokeNotification object:nil];
    
    //THOUGHTS: something to do in the future
    //notify friends and challengers
}


#pragma mark - CHECK TIMER
- (void)scheduleAlarmTimer {
    if (![EWPerson me]) return;
    EWActivity *activity = [EWPerson myCurrentAlarmActivity];
    if (!activity) {
        DDLogInfo(@"No activity found. Possibly no alarm turned on.");
        return;
    }
    //alarm time up
	NSTimeInterval timeLeft = activity.time.timeIntervalSinceNow;
    
    [self.alarmTimer invalidate];
    
    DDLogInfo(@"Scheduled alarm timer in %@", [NSDate getStringFromTime:timeLeft]);
    self.alarmTimer = [NSTimer bk_scheduledTimerWithTimeInterval:timeLeft block:^(NSTimer *timer) {
        DDLogInfo(@"Alarm timer up! start to wake up!");
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmTimerDidFireNotification object:nil];
        
        //start to wake up
        [[EWWakeUpManager sharedInstance] startToWakeUp];
        
        //schedule timer
        //fire an alarm
//        DDLogVerbose(@"=============> Firing Alarm timer notification <===============");
//        UILocalNotification *note = [[UILocalNotification alloc] init];
//        note.alertBody = [NSString stringWithFormat:@"It's time to wake up (%@)", [activity.time date2String]];
//        note.alertAction = @"Wake up!";
//        //alarm.soundName = me.preference[@"DefaultTone"];
//        note.userInfo = @{kActivityLocalID: activity.objectID.URIRepresentation.absoluteString,
//                          kLocalNotificationTypeKey: kLocalNotificationTypeAlarmTimer};
//        [[UIApplication sharedApplication] scheduleLocalNotification:note];
    } repeats:NO];
    
    //sleep status switch
    static NSTimer *wakeableTimer;
    [wakeableTimer invalidate];
    wakeableTimer = [NSTimer bk_scheduledTimerWithTimeInterval:timeLeft - kMaxEarlyWakeHours*3600 block:^(NSTimer *timer) {
        
        //broadcast wake enabled status
        [[NSNotificationCenter defaultCenter] postNotificationName:kEWWakeEnabled object:nil];
        //also check voices
        [[EWMediaManager sharedInstance] checkNewMediasWithCompletion:^(NSArray *array, NSError *error) {
            DDLogInfo(@"Found %lu new medias", (unsigned long)array.count);
            if ([EWPerson myUnreadMedias].count == 0) {
                [[EWMediaManager sharedInstance] getWokeVoiceWithCompletion:NULL];
            }
        }];
    } repeats:NO];
    
    //sleep status switch
    static NSTimer *wakeUpTimeout;
    [wakeUpTimeout invalidate];
    wakeUpTimeout = [NSTimer bk_scheduledTimerWithTimeInterval:timeLeft + kMaxWakeTime block:^(NSTimer *timer) {
        
        //broadcast wake enabled status
        [[NSNotificationCenter defaultCenter] postNotificationName:kWokeNotification object:nil];

    } repeats:NO];
}


#pragma mark - Play for wake up view
- (void)startToPlayVoice{
    [self loadUnreadMedias];
	//play
	self.currentMediaIndex = @(-1);
	self.continuePlay = YES;
	//[self playNextVoice];
	[EWAVManager sharedManager].audioFinishBlock = ^(NSError *error){
		DDLogInfo(@"Finished playing rington, start to play audio.");
		[self playNextVoice];
	};
	NSString *ringtone = [EWPerson me].preference[@"DefaultTone"];
	[[EWAVManager sharedManager] playSoundFromFileName:ringtone];
	
	//volume
	[EWAVManager sharedManager].player.volume = 0;
    [[EWAVManager sharedManager] volumeTo:1 withCompletion:^{
		DDLogVerbose(@"Volume adjusted to full");
    }];
}

- (void)playNextVoiceWithDelay {
    //no continue to play if status is not waking up
    if ([EWSession sharedSession].wakeupStatus != EWWakeUpStatusWakingUp) {
        DDLogVerbose(@"Continueus playing disabled for state other than waking up");
        return;
    }
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
	
	self.currentMediaIndex = @(_currentMediaIndex.integerValue+1);
    if (self.currentMediaIndex.unsignedIntegerValue <= _medias.count - 1){
        //get next cell
        DDLogInfo(@"Play next song (%@)", self.currentMediaIndex);
        [[EWAVManager sharedManager] playMedia:self.currentMedia];
        [[NSNotificationCenter defaultCenter] postNotificationName:kEWWakeUpDidPlayNextMediaNotification object:nil];
    }
    else { //index == _medias.count
        if ((self.loopCount)>0) {
            //play the first if loopCount > 0
            DDLogInfo(@"Looping, %ld loop left", (long)_loopCount);
            self.loopCount++;
            self.currentMediaIndex = @0;
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
	self.currentMediaIndex = @0;
    [[EWAVManager sharedManager] volumeTo:0 withCompletion:^{
        [[EWAVManager sharedManager] stopAllPlaying];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:kEWWakeUpDidStopPlayMediaNotification object:nil];
}

- (void)playMediaAtIndex:(NSUInteger)index {
    self.currentMediaIndex = @(index);
    [[EWAVManager sharedManager] playMedia:self.currentMedia];
	[[NSNotificationCenter defaultCenter] postNotificationName:kEWWakeUpDidPlayNextMediaNotification object:nil];
}

- (void)playMedia:(EWMedia *)media {
    NSUInteger index = [self.medias indexOfObject:media];
    if (index == NSNotFound) {
        DDLogError(@"Media not found");
        NSAssert(false, @"Media not found");
    }
    [self playMediaAtIndex:index];
}

- (void)loadUnreadMedias{
	BOOL forceLoad = NO;
#ifdef DEBUG
	//forceLoad = YES;
#endif
	
    if ([EWSession sharedSession].wakeupStatus == EWWakeUpStatusWakingUp || forceLoad) {
        self.medias = [EWPerson myUnreadMedias];
        DDLogInfo(@"Reloaded media and current media is %ld", (unsigned long)self.medias.count);
    }else{
        DDLogVerbose(@"Current seesion is not in wakingUp mode, playing media list will not load from myUnreadMedias");
    }
}

- (EWMedia *)currentMedia {
    if (_currentMediaIndex.unsignedIntegerValue >= self.medias.count && [EWSession sharedSession].wakeupStatus == EWWakeUpStatusWakingUp) {
        DDLogError(@"currentMedia index overflow");
        return nil;
    }
    return self.medias[_currentMediaIndex.unsignedIntegerValue];
}

#pragma mark - Test
- (void)testWakeUpInSeconds:(NSInteger)seconds{
    [EWWakeUpManager sharedInstance].skipCheckActivityCompleted = YES;
    EWAlarm *testingAlarm;
    for (EWAlarm *alarm in [EWPerson myAlarms]) {
        if (alarm.time.mt_weekdayOfWeek == [NSDate date].mt_weekdayOfWeek) {
            testingAlarm = alarm;
        }
    }
    EWActivity *activity = [[EWActivityManager sharedManager] activityForAlarm:testingAlarm];
    NSDate *newTime = [[NSDate date] mt_dateByAddingYears:0 months:0 weeks:0 days:0 hours:0 minutes:0 seconds:seconds];
    testingAlarm.time = newTime;
    activity.time = newTime;
    NSUInteger mediaCount = activity.mediaIDs.count;
    activity.mediaIDs = [NSMutableArray array];
    DDLogVerbose(@"Removed %lu medias from activity, now unreadMedias cound is %lu", (unsigned long)mediaCount, (unsigned long)[EWPerson myUnreadMedias].count);
    DDLogDebug(@"Activity %@ and Alarm %@ changed to %@", activity.serverID, testingAlarm.serverID, newTime.string);
	[[EWWakeUpManager shared] scheduleAlarmTimer];
	
	NSString *str = [NSString stringWithFormat:@"Alarm will show in %lds", (long)seconds];
    [EWUIUtil showSuccessHUBWithString:str];
    self.tempActivity = activity;
}
@end
