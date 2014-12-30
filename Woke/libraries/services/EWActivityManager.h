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
/**
 *  Get the acitivity that is for current alarm
 *  If current activity is completed or mismatch with current alarm, generate a new activity
 *  The returned activity is the next valid alarm activity that is neither completed or 
 */
@property (nonatomic, strong) EWActivity *currentAlarmActivity;
+ (EWActivityManager *)sharedManager;

//methods
- (NSArray *)activitiesForPerson:(EWPerson *)person inContext:(NSManagedObjectContext *)context;
- (EWActivity *)activityForAlarm:(EWAlarm *)alarm;
- (EWActivity *)currentAlarmActivityForPerson:(EWPerson *)person;
- (void)completeAlarmActivity:(EWActivity *)activity;
@end
