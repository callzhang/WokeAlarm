//
//  EWStatisticsManager.m
//  EarlyWorm
//
//  Created by Lei on 1/8/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWCachedInfoManager.h"
#import "EWUIUtil.h"
#import "EWMediaManager.h"
#import "EWMedia.h"
#import "EWActivity.h"
#import "EWActivityManager.h"


@implementation EWCachedInfoManager
//TODO: There is unfinished work
//The manager should monitor my activities and update the statistics automatically

+ (EWCachedInfoManager *)managerWithPerson:(EWPerson *)p{
    EWCachedInfoManager *manager = [EWCachedInfoManager new];
    manager.person = p;
    if (p.isMe) {
        //newest on top
        manager.activities = [EWPerson myActivities];
        [p addObserver:self forKeyPath:EWPersonRelationships.activities options:NSKeyValueObservingOptionNew context:nil];
    }else{
        [manager getStatsFromCache];
    }
    return manager;
}

+ (EWCachedInfoManager *)myStatsManager{
    return [EWCachedInfoManager managerWithPerson:[EWPerson me]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isKindOfClass:[EWPerson class]]) {
        if ([keyPath isEqualToString:EWPersonRelationships.activities]) {
            DDLogInfo(@"Activity changed detected and statistics updated");
            [self updateStatistics];
        }
    }
}

- (void)getStatsFromCache{
    
    //load cached info
    NSDictionary *stats = self.person.cachedInfo[kStatsCache];
    self.aveWakingLength = stats[kAveWakeLength];
    self.aveWakeUpTime = stats[kAveWakeTime];
    self.successRate = stats[kSuccessRate];
    self.wakability = stats[kWakeability];
}

- (void)setStatsToCache{
    NSMutableDictionary *cache = self.person.cachedInfo.mutableCopy;
    NSMutableDictionary *stats = [cache[kStatsCache] mutableCopy]?:[NSMutableDictionary new];
    
    stats[kAveWakeLength] = self.aveWakingLength;
    stats[kAveWakeTime] = self.aveWakeUpTime;
    stats[kSuccessRate] = self.successRate;
    stats[kWakeability] = self.wakability;
    
    cache[kStatsCache] = stats;
    self.person.cachedInfo = cache;
    [EWSync save];
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
    
    if (_activities.count) {
        NSInteger totalTime = 0;
        NSUInteger wakes = 0;
        
        for (EWActivity *activity in self.activities) {
            
            wakes++;
            NSInteger length;
            if (activity.completed) {
                length = MAX([activity.completed timeIntervalSinceDate:activity.time], kMaxWakeTime);
            }else{
                length = kMaxWakeTime;
            }
            
            totalTime += length;
        }
        NSInteger aveTime = totalTime / wakes;
        _aveWakingLength = [NSNumber numberWithInteger:aveTime];
        [self setStatsToCache];
        return _aveWakingLength;
    }
    return 0;
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
    if (_successRate) {
        return _successRate;
    }
    
    if (_activities.count) {
        float rate = 0.0;
        float wakes = 0;
        float totalWakes = 0;
        
        for (EWActivity *activity in self.activities) {
            if ([activity.type isEqualToString:EWActivityTypes.alarm]) {
                totalWakes++;
                if (activity.completed && [activity.completed timeIntervalSinceDate:activity.time] < kMaxWakeTime) {
                    wakes++;
                }
            }
           
        }
        rate = wakes / totalWakes;
        
        _successRate =  [NSNumber numberWithFloat:rate];
        [self setStatsToCache];
        return _successRate;
    }
    return 0;
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
    
    if (_activities.count) {
        double ratio = MIN(self.aveWakingLength.integerValue / kMaxWakabilityTime, 1);
        double level = 10 - ratio*10;
        _wakability = [NSNumber numberWithDouble:level];
        [self setStatsToCache];
        return _wakability;
    }
    return 0;
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
    
    if (_activities.count) {
        NSInteger totalTime = 0;
        NSUInteger wakes = 0;
        
        for (EWActivity *activity in self.activities) {
            
            wakes++;
            totalTime += activity.time.minutesFrom5am;
        }
        NSInteger aveTime = totalTime / wakes;
        NSDate *time = [[NSDate date] timeByMinutesFrom5am:aveTime];
        _aveWakeUpTime = time.date2String;
        [self setStatsToCache];
        return _aveWakeUpTime;
    }
    
    return @"-";
}


#pragma mark - Update Activity
- (void)updateActivityCacheWithCompletion:(void (^)(void))block{
    //TODO
    NSParameterAssert([_person isMe]);
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        EWPerson *localPerson = [_person MR_inContext:localContext];
        NSArray *activities = [localPerson.activities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWActivityAttributes.time ascending:NO]]];//newest on top
        
        NSSet *medias = localPerson.medias;
        NSMutableDictionary *cache = localPerson.cachedInfo.mutableCopy;
        NSMutableDictionary *activityCache = [cache[kActivityCache] mutableCopy]?:[NSMutableDictionary new];
        if (activityCache.count == activities.count) {
            NSLog(@"=== cached activities count is same as past _activity count (%ld)", (long)activities.count);
            return;
        }
        
        for (NSUInteger i =0; i<activities.count; i++) {
            //start from the newest task
            EWActivity *_activity = activities[i];
            if ([_activity.type isEqualToString:EWActivityTypes.media]) {
                NSDate *wakeTime;
                //NSArray *wokeTo;
                
                
                if (_activity.completed && [_activity.completed timeIntervalSinceDate:_activity.time] < kMaxWakeTime) {
                    wakeTime = _activity.completed;
                }else{
                    wakeTime = [_activity.time dateByAddingTimeInterval:kMaxWakeTime];
                }
                
                NSDate *eod = _activity.time.endOfDay;
                NSDate *bod = _activity.time.beginingOfDay;
                
                //woke to receivers
                NSSet *wokeTo = [medias filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"%K < %@ & %K > %@", EWServerObjectAttributes.updatedAt, eod, EWServerObjectAttributes.updatedAt, bod]];
                
                
                //woke by sender
                NSArray *wokeBy = [NSArray new];
                NSMutableArray *senders = [NSMutableArray new];
                for (EWMedia *m in _activity.medias) {
                    NSString *sender = m.author.objectId;
                    if (!sender) continue;
                    [senders addObject:sender];
                }
                wokeBy = senders.copy;
                
                @try {
                    NSDictionary *taskActivity = @{kActivityType: _activity.type,
                                                   kActivityTime: _activity.time,
                                                   kWokeTime: wakeTime,
                                                   kWokeTo: wokeTo.allObjects,
                                                   kWokeBy: wokeBy};
                    
                    NSString *dateKey = _activity.time.date2YYMMDDString;
                    activityCache[dateKey] = taskActivity;
                }
                @catch (NSException *exception) {
                    NSLog(@"*** Failed to generate activity: %@", exception.description);
                }
            }
            
            
            
        }
        
        cache[kActivityCache] = [activityCache copy];
        localPerson.cachedInfo = [cache copy];
        
        NSLog(@"_activity activity cache updated with %lu records", (unsigned long)activityCache.count);

    } completion:^(BOOL success, NSError *error) {
        NSLog(@"Finished updating activity cache");
        if (block) {
            block();
        }
    }];
    
}

- (void)updateCacheWithFriendsAdded:(NSArray *)friendIDs{
    NSMutableDictionary *cache = [EWSession sharedSession].currentUser.cachedInfo.mutableCopy;
    NSMutableDictionary *activity = [cache[kActivitiesCache] mutableCopy]?:[NSMutableDictionary new];
    NSMutableDictionary *friendsActivityDic = [activity[kFriended] mutableCopy] ?:[NSMutableDictionary new];
    NSString *dateKey = [NSDate date].date2YYMMDDString;
    NSArray *friendedArray = friendsActivityDic[dateKey]?:[NSArray new];
    NSMutableSet *friendedSet = [NSMutableSet setWithArray:friendedArray];;
    
    [friendedSet addObjectsFromArray:friendIDs];
    
    friendsActivityDic[dateKey] = [friendedSet allObjects];
    activity[kFriended] = [friendsActivityDic copy];
    cache[kActivitiesCache] = [activity copy];
    [EWSession sharedSession].currentUser.cachedInfo = [cache copy];
    
    [EWSync save];
}

@end