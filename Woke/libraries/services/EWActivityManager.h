//
//  EWActivityManager.h
//  Woke
//
//  Created by Lei Zhang on 10/29/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"

//#define kNotificationTypeActivityHasNewMedia    @"activity_new_media"

extern NSString *const EWActivityTypeAlarm;
extern NSString *const EWActivityTypeFriendship;
extern NSString *const EWActivityTypeMedia;



@interface EWActivityManager : NSObject
@property (nonatomic, strong) EWActivity *currentAlarmActivity;
+ (EWActivityManager *)sharedManager;

//Shortcut
+ (NSArray *)myActivities;
+ (NSArray *)myAlarmActivities;
- (NSArray *)activitiesForPerson:(EWPerson *)person inContext:(NSManagedObjectContext *)context;
- (EWActivity *)currentAlarmActivityForPerson:(EWPerson *)person;
- (void)completeAlarmActivity:(EWActivity *)activity;
@end
