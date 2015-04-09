//
//  EWWakeUpManager.h
//
//  For detailed process diagram
//  https://www.lucidchart.com/documents/view/92f751f4-f226-430f-8526-cbb93730f251
//
//  Created by Lei on 3/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWMedia.h"
#define kNewNediaPlaying        @"new_media_playing"
#define kLoopMediaPlayCount     100
#define kMaxEarlySleepHours		3
#define kMaxEarlyWakeHours      1.5
#define kEWWakeEnabled          @"wake_enabled"

@import UIKit;
@class EWActivity, EWAlarm, EWPerson, EWWakeUpManager;
NSUInteger static maxLoop = 100;

extern NSString * const kAlarmTimerDidFireNotification;
extern NSString * const kEWWakeUpDidPlayNextMediaNotification;
extern NSString * const kEWWakeUpDidStopPlayMediaNotification;

@protocol EWWakeUpDelegate <NSObject>
@required
- (BOOL)wakeupManager:(EWWakeUpManager *)manager shouldWakeUpWithAlarm:(EWAlarm *)alarm;

@optional
- (void)wakeUpManagerWillWakeUp:(EWWakeUpManager*)wakeUpManager;
- (void)wakeUpManagerDidWakeUp:(EWWakeUpManager*)wakeUpManager;
@end



@interface EWWakeUpManager : NSObject
@property (nonatomic, copy) NSArray *medias;
@property (nonatomic, weak) NSObject<EWWakeUpDelegate> *delegate;
@property (nonatomic, readonly) BOOL canStartToWakeUp;

//play control
@property (nonatomic, assign) BOOL continuePlay;
@property (nonatomic) NSUInteger loopCount;
@property (nonatomic, readonly) EWMedia *currentMedia;
@property (nonatomic, strong) NSNumber *currentMediaIndex;


//for testing
@property (nonatomic, assign) BOOL forceSleep;
@property (nonatomic, assign) BOOL forceSnooze;
@property (nonatomic, assign) BOOL forceWakeUp;
@property (nonatomic, assign) BOOL skipCheckActivityCompleted;


GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(EWWakeUpManager)

#pragma mark - Start to wake up
/**
 Handle alarm time up event
 1. Get next activity
 2. Try to download all medias for task
 3. If there is no media, create a woke media
 4. After download all medias
    a. cancel local notification
    b. fire silent local notification [lock screen]
    c. present wakeupVC and start play in 15s
 */
- (void)startToWakeUp;

- (void)startToWakeUpWithAlarm:(EWAlarm *)alarm;

#pragma mark - Sleep
/**
 *  Handle the sleep timer event
 *
 *  @param notification the notification used to identify which alarm/activity it is going to sleep for. Pass nil to sleep for current alarm/activity
 */
- (void)sleep:(NSDictionary *)userInfo;
- (void)unsleep;
- (BOOL)shouldSleep;
- (BOOL)canSnooze;

#pragma mark - Wake
/**
 Release the reference to wakeupVC
 Post notification: kWokeNotification
 */
- (void)wake:(EWActivity *)activity;

#pragma mark - Timer check
/**
 Timely alarm timer check task
 Will schedule an alarm if the time left is within the service update interval
 Call handle alarm timer method when time is up
 */
- (void)scheduleAlarmTimer;
//- (void)alarmTimerCheck;

//- (void)sleepTimerCheck;

#pragma mark - Play control
/**
 *  The single API exposed for playing sound
 */
- (void)playNextVoice;
/**
 *  Play the n'th voice
 *
 */
- (void)playMediaAtIndex:(NSUInteger)index;
- (void)playMedia:(EWMedia *)media;
/**
 *  The current waker for the voice that is being played
 *
 *  @return The waker
 */
- (void)loadUnreadMedias;
- (void)stopPlayingVoice;

#pragma mark - Test
- (void)testWakeUpInSeconds:(NSInteger)seconds;
@end
