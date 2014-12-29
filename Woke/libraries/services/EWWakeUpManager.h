//
//  EWWakeUpManager.h
//  EarlyWorm
//
//  Created by Lei on 3/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kNewNediaPlaying        @"new_media_playing"
#define kLoopMediaPlayCount             100

@import UIKit;
@class EWActivity, EWAlarm, EWPerson;
NSUInteger static maxLoop = 100;

@interface EWWakeUpManager : NSObject
//@property (nonatomic, strong) EWAlarm *alarm;
//@property (nonatomic, strong) EWActivity *currentActivity;
@property (nonatomic, strong) NSArray *medias;
@property (nonatomic) NSUInteger loopCount;
@property (nonatomic) EWMedia *currentMedia;
//@property (nonatomic) BOOL isWakingUp;//moved to session manager
@property (nonatomic) BOOL continuePlay;

+ (EWWakeUpManager *)sharedInstance;

/**
 *Handles push media in varies mode
 @Discuss
 *1. Buzz
 *   active: sound + wakeupView
 *   suspend: not handle
 *
 *2. Voice
 *   active:
 *       alarm time passed but not woke(struggle): play media
 *       before alarm: download
 *       woke: alert with no name
 *   suspend: background download
 */
- (void)handlePushMedia:(NSDictionary *)notification;

/**
 Handle alarm time up event
 1. Get next task
 2. Try to download all medias for task
 3. If there is no media, create a pesudo media
 4. After download
    a. cancel local notif
    b. fire silent alarm
    c. present wakeupVC and start play in 30s
 */
- (void)handleAlarmTimerEvent:(NSDictionary *)pushInfo;

/**
 *  Handle the sleep timer event
 *
 *  @param notification the notification used to identify which alarm/activity it is going to sleep for.
 */
- (void)handleSleepTimerEvent:(UILocalNotification *)notification;

/**
 Detect if root view is presenting EWWakeUpViewController
 */
+ (BOOL)isRootPresentingWakeUpView;

/**
 Timely alarm timer check task
 Will schedule an alarm if the time left is within the service update interval
 Call handle alarm timer method when time is up
 */
- (void)alarmTimerCheck;

- (void)sleepTimerCheck;

#pragma mark - Sleep/Wake related
/**
 Release the reference to wakeupVC
 Post notification: kWokeNotification
 */
- (void)wake;

/**
 *  Prepare to wake
 */
- (void)startToWake;

/**
 *  Handles the sleep action.
 *  When called, the app goes to sleep status
 */
- (void)sleep;


#pragma mark - Play for wakeup view
/**
 *  The single API exposed for playing sound
 */
- (void)playNextVoice;
/**
 *  Play the n'th voice
 *
 */
- (void)playVoiceAtIndex:(NSUInteger)n;
/**
 *  The current waker for the voice that is being played
 *
 *  @return The waker
 */
- (void)reloadMedias;
- (void)stopPlayingVoice;
- (NSUInteger)currentMediaIndex;

@end
