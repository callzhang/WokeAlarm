//
//  EWPerson(Woke).h
//  Woke
//
//  Created by Lei Zhang on 12/25/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWPerson.h"

@interface EWPerson(Woke)
+ (EWPerson *)me;
+ (EWPerson *)meInContext:(NSManagedObjectContext *)context;
- (BOOL)isMe;

//my stuff
+ (NSArray *)myActivities;
+ (NSArray *)myAlarmActivities;
+ (NSArray *)myUnreadNotifications;
+ (NSArray *)myNotifications;
+ (NSArray *)myAlarms;
+ (NSArray *)myFriends;
+ (EWSocial *)mySocialGraph;

- (void)updateStatus:(NSString *)status completion:(void (^)(NSError *error))completion;

+ (EWAlarm *)myCurrentAlarm;
+ (EWActivity *)myCurrentAlarmActivity;
+ (NSArray *)myUnreadMedias;

//social
- (BOOL)isFriend;
- (BOOL)friendPending;
- (BOOL)friendWaiting;
- (void)updateMyCachedFriends;
- (void)requestFriend:(EWPerson *)person;
- (void)acceptFriend:(EWPerson *)person;
- (void)unfriend:(EWPerson *)person;


@end
