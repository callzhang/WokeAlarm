//
//  EWStatisticsManager.m
//  WokeAlarm
//
//  Created by Lei on 1/8/14.
//  Copyright (c) 2014 Woke. All rights reserved.
//

#import "EWCachedInfoManager.h"
#import "EWUIUtil.h"
#import "EWMediaManager.h"
#import "EWMedia.h"
#import "EWActivity.h"
#import "EWActivityManager.h"
#import <KVOController/FBKVOController.h>
#import "EWAlarm.h"
#import "NSDictionary+KeyPathAccess.h"
#import "NSDate+MTDates.h"

@implementation EWCachedInfoManager
//The manager should monitor my activities and update the statistics automatically
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS(EWCachedInfoManager)

//Update stats automatically for me
- (void)startAutoCacheUpdateForMe{
    NSAssert(self == [EWCachedInfoManager shared], @"Self is not the shared instance!");
    EWAssertMainThread
    
    //set me
    self.currentPerson = [EWPerson me];
    
    //observe activities
    [self.KVOController observe:[EWPerson me] keyPath:EWPersonRelationships.activities options:0 block:^(id observer, id object, NSDictionary *change) {
		//If the value of the NSKeyValueChangeKindKey entry is NSKeyValueChangeInsertion, NSKeyValueChangeRemoval, or NSKeyValueChangeReplacement, the value of this key is an NSIndexSet object that contains the indexes of the inserted, removed, or replaced objects.
        if (change[NSKeyValueChangeIndexesKey]) {
            DDLogInfo(@"CachedManager detected Activity change, detected and statistics updated: %@", change[NSKeyValueChangeIndexesKey]);
            [self updateStatistics];
            //[self updateActivityCacheWithCompletion:nil];
        }
    }];
    
    //observer friends
    [self.KVOController observe:[EWPerson me] keyPath:EWPersonRelationships.friends options:0 block:^(id observer, id object, NSDictionary *change) {
		//If the value of the NSKeyValueChangeKindKey entry is NSKeyValueChangeInsertion, NSKeyValueChangeRemoval, or NSKeyValueChangeReplacement, the value of this key is an NSIndexSet object that contains the indexes of the inserted, removed, or replaced objects.
        if (change[NSKeyValueChangeIndexesKey]) {
            DDLogInfo(@"CachedManager detected friends change, updating cachedFriends: %@",change[NSKeyValueChangeIndexesKey]);
            [self updateCachedFriends];
        }
    }];
    
    //update stats then update stats
//    [self updateActivityCacheWithCompletion:^{
//        [self updateStatistics];
//    }];
}

//for others
+ (instancetype)managerForPerson:(EWPerson *)person{
	//NSParameterAssert(!person.isMe);
    EWCachedInfoManager *manager = [EWCachedInfoManager new];
    manager.currentPerson = person;
    [manager loadStatsFromCache];
    return manager;
}

- (void)loadStatsFromCache{

    //load cached info
    NSDictionary *stats = self.currentPerson.cachedInfo[kStatsCache];
    self.aveWakingLength = stats[kAveWakeLength]?:@kMaxWakeTime;
    self.aveWakeUpTime = stats[kAveWakeTime]?:@0;
    self.successRate = stats[kSuccessRate]?:@0;
    self.wakability = stats[kWakeability]?:@0;
    self.averageSleepLength = stats[kAverageSleepLength]?:@0;
}

- (void)setStatsToCache{
    NSParameterAssert(_currentPerson.isMe);
    NSMutableDictionary *stats = [NSMutableDictionary new];
    
    stats[kAveWakeLength] = self.aveWakingLength;
    stats[kAveWakeTime] = self.aveWakeUpTime;
    stats[kSuccessRate] = self.successRate;
    stats[kWakeability] = self.wakability;
    stats[kAverageSleepLength] = self.averageSleepLength;
    
    _currentPerson.cachedInfo = [_currentPerson.cachedInfo setValue:stats forImmutableKeyPath:@[kStatsCache]];
    [_currentPerson save];
}

- (void)updateStatistics{
    self.aveWakingLength = nil;
    self.aveWakeUpTime = nil;
    self.successRate = nil;
    self.wakability = nil;
    [self setStatsToCache];
}

- (NSNumber *)aveWakingLength{
    if (_aveWakingLength) {
        return _aveWakingLength;
   } 
    
    if (_currentPerson.activities.count) {
        NSInteger totalTime = 0;
        NSUInteger wakes = 0;
        NSInteger aveTime = 0;
        
        for (EWActivity *activity in self.currentPerson.activities) {
            
            wakes++;
            NSInteger length;
            if (activity.completed) {
                length = MAX([activity.completed timeIntervalSinceDate:activity.time], kMaxWakeTime);
            }else{
                length = kMaxWakeTime;
            }
            
            totalTime += length;
        }
        if (wakes > 0) {
            aveTime = totalTime / wakes;
            _aveWakingLength = [NSNumber numberWithInteger:aveTime];
        }
        
        return _aveWakingLength;
    }
    return @kMaxWakeTime;
}

- (NSString *)aveWakingLengthString{
    NSInteger aveT = self.aveWakingLength.integerValue;
    if (aveT == 0) {
        return @"-";
    }
    NSString *str = [NSDate getStringFromTime:aveT];
    return str;
}

- (NSNumber *)successRate{
    if (_averageSleepLength) {
        return _averageSleepLength;
    }
    
    if (_currentPerson.activities.count) {
        float rate = 0.0;
        float wakes = 0;
        float totalWakes = 0;
        
        for (EWActivity *activity in self.currentPerson.activities) {
            totalWakes++;
            if (activity.completed && [activity.completed timeIntervalSinceDate:activity.time] < kMaxWakeTime) {
                wakes++;
            }
           
        }
        rate = wakes / totalWakes;
        
        _averageSleepLength =  [NSNumber numberWithFloat:rate];
        return _averageSleepLength;
    }
    return @0;
}

- (NSString *)averageSleepLengthString{
    NSString *str = [NSDate getStringFromTime:self.averageSleepLengthString.doubleValue];
    return str;
}

- (NSNumber *)averageSleepLength{
    if (_successRate) {
        return _successRate;
    }
    if (_currentPerson.activities.count) {
        float length = 0.0;
        float wakes = 0;
        
        for (EWActivity *activity in self.currentPerson.activities) {
            if (activity.completed && activity.sleepTime) {
                wakes++;
                length += [activity.completed timeIntervalSinceDate:activity.sleepTime];
            }
            
        }
        
        _successRate =  [NSNumber numberWithFloat:length/wakes];
        return _successRate;
    }
    return @0;
}

- (NSString *)successString{
    float rate = self.successRate.floatValue;
    NSString *rateStr = [NSString stringWithFormat:@"%f%%", rate];
    return rateStr;
}

- (NSNumber *)wakability{
    if (_wakability) {
        return _wakability;
    }
    
    if (_currentPerson.activities.count) {
        double ratio = MIN(self.aveWakingLength.integerValue / kMaxWakabilityTime, 1);
        double level = 10 - ratio*10;
        _wakability = [NSNumber numberWithDouble:level];
        return _wakability;
    }
    return @0;
}

- (NSString *)wakabilityStr{
    double level = self.wakability.floatValue;
    NSString *lvString = [NSString stringWithFormat:@"%ld/10", (long)level];
    return lvString;
}

- (NSString *)aveWakeUpTime{
    if (_aveWakeUpTime) {
        return _aveWakeUpTime;
    }
    
    if (_currentPerson.activities.count) {
        NSInteger totalTime = 0;
        NSUInteger wakes = 0;
        NSInteger aveTime = 0;
        NSDate *time;
        for (EWActivity *activity in self.currentPerson.activities) {
            
            wakes++;
            totalTime += activity.time.minutesFrom5am;
        }
        if (wakes > 0) {
            aveTime = totalTime / wakes;
            time = [[NSDate date] timeByMinutesFrom5am:aveTime];
        }
        _aveWakeUpTime = time.date2String;
        return _aveWakeUpTime;
    }
    
    return @"-";
}


#pragma mark - Update cache
////Snapshot activity cache and save to cachedInfo (Unused)
//- (void)updateActivityCacheWithCompletion:(VoidBlock)block{
//    NSAssert(YES, @"Activity should not be updated to cache anymore");
//    NSParameterAssert([_currentPerson isMe]);
//    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
//        EWPerson *localMe = [EWPerson meInContext:localContext];
//        NSArray *activities = [localMe.activities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWActivityAttributes.time ascending:NO]]];//newest on top
//        
//        NSDictionary *activityCache = localMe.cachedInfo[kActivityCache];
//        
//        //check if update is necessary
//        if (activityCache.count == activities.count) {
//            DDLogVerbose(@"=== cached activities count is same as past _activity count (%ld)", (long)activities.count);
//            return;
//        }
//        
//        for (EWActivity *activity in activities) {
//            if (!activity.completed || !activity.time) {
//                DDLogDebug(@"Skip current Activity");
//                continue;
//            }
//            
//            NSString *dateKey = activity.time.date2YYMMDDString;
//            //check if we need to update
//            if (activityCache[dateKey]) continue;
//            
//            //start from the newest task
//            NSDate *wakeTime;
//            if (activity.completed && [activity.completed timeIntervalSinceDate:activity.time] < kMaxWakeTime) {
//                wakeTime = activity.completed;
//            }else{
//                wakeTime = [activity.time dateByAddingTimeInterval:kMaxWakeTime];
//                activity.completed = wakeTime;
//            }
//            
//            NSDate *eod = activity.time.endOfDay;
//            NSDate *bod = activity.time.beginingOfDay;
//            
//            //woke to receivers
//            NSSet *wokeTo = [localMe.sentMedias filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"%K < %@ AND %K > %@", EWServerObjectAttributes.updatedAt, eod, EWServerObjectAttributes.updatedAt, bod]];
//            //woke by sender
//            NSArray *wokeBy = activity.mediaIDs;
//            NSDictionary *activityLog;
//            @try {
//                activityLog = @{kActivityType: activity.type,
//                                kActivityTime: activity.time?:@0,
//                                    kWokeTime: activity.completed?:@0,
//									kWokeTo: wokeTo.allObjects,
//									kWokeBy: wokeBy?:@0};
//                
//                //activityCache[dateKey] = activityLog;
//            }
//            @catch (NSException *exception) {
//                DDLogError(@"*** Failed to generate activity: %@", exception.description);
//                continue;
//            }
//            
//            localMe.cachedInfo = [localMe.cachedInfo setValue:activityLog forImmutableKeyPath:@[kActivityCache, dateKey]];
//            DDLogVerbose(@"activity activity cache updated on %@", dateKey);
//        }
//    } ];
//}

- (void)updateCachedFriends{
    NSSet *friends = [[EWPerson me].friends valueForKey:kParseObjectID];
    NSDictionary *cache = [EWPerson me].cachedInfo;
    NSArray *cachedFriends = cache[kCachedFriends]?:[NSArray new];
    if (![friends isEqualToSet:[NSSet setWithArray:cachedFriends]]) {
        [EWPerson me].cachedInfo = [cache setValue:friends.allObjects forImmutableKeyPath:@[kCachedFriends]];
        [[EWPerson me] save];
    }
}

- (void)updateCachedAlarmTimes{
	for (EWAlarm *alarm in [EWPerson me].alarms) {
		[alarm updateCachedAlarmTime];
	}
}

- (void)updateCachedStatements{
	for (EWAlarm *alarm in [EWPerson me].alarms) {
		[alarm updateCachedStatement];
	}
}

@end
