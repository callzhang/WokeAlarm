//
//  EWStatisticsManager.h
//  EarlyWorm
//
//  Created by Lei on 1/8/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//
//  The statisticsManager managers stats of person, and activity logs. Both of which stores in EWPerson's cachedInfo.
//  For current user, the manager must be initiated with shared instance, and then call startAutoCacheUpdateForPerson to start update cache automatically
//  For other user, it is a instance that extract helpful info from Person's cachedInfo. We should use "managerForPerson" to init the manager.

#import <Foundation/Foundation.h>
#import "EWPerson.h"

#define kMaxWakabilityTime	600

//alarm
//#define kCachedAlarmTimes   @"alarm_schedule"
//#define kCachedStatements   @"statements"

//stats
#define kStatsCache         @"stats_cache"
#define kAveWakeLength      @"ave_wake_length"
#define kAveWakeTime        @"ave_wake_time"
#define kSuccessRate        @"ave_success_rate"
#define kWakeability        @"wakeability"

//activity
#define kActivityCache      @"activity_cache"
#define kActivityType       @"type"
#define kActivityTime       @"time"
#define kWokeTime           @"wake"
#define kWokeBy             @"woke_by"
#define kWokeTo             @"woke_to"

//activities
#define kActivitiesCache    @"activities_cache"
#define kFriended           @"friended"
#define kChallengesFinished @"challenges_finished"
#define kTasksFinished      @"task_finished"
#define kAchievements       @"achievements"

@interface EWCachedInfoManager : NSObject

@property (nonatomic) EWPerson *currentPerson;
@property (nonatomic) NSNumber *aveWakingLength;
@property (nonatomic) NSString *aveWakingLengthString;
@property (nonatomic) NSString *aveWakeUpTime;
@property (nonatomic) NSNumber *successRate;
@property (nonatomic) NSString *successString;
@property (nonatomic) NSNumber *wakability;
@property (nonatomic) NSString *wakabilityStr;

GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(EWCachedInfoManager);
+ (instancetype)managerForPerson:(EWPerson *)person;

//cachedInfo management
- (void)startAutoCacheUpdateForMe;
/**
 * Snapshot activity cache and save to cachedInfo 
 @attention Currently the cached activities are unused 
 */
- (void)updateActivityCacheWithCompletion:(VoidBlock)block;
- (void)updateCachedFriends;
- (void)updateCachedAlarmTimes;
- (void)updateCachedStatements;

//Helper
+ (void)setCachedInfoWithValue:(id)value forKeyPath:(NSArray *)keyPathArray;
@end
