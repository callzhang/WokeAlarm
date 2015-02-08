//
//  EWPerson(Woke).h
//  Woke
//
//  Created by Lei Zhang on 12/25/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWPerson.h"

typedef NS_ENUM(NSInteger, EWFriendshipStatus){
    EWFriendshipStatusNone,
    EWFriendshipStatusDenied,
    EWFriendshipStatusSent,
    EWFriendshipStatusReceived,
    EWFriendshipStatusFriended,
    EWFriendshipStatusUnknown
};

extern NSString * const kFriendshipStatusChanged;

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
- (EWFriendshipStatus)friendshipStatus;
- (void)requestFriend:(EWPerson *)person __deprecated;//use - (void)requestFriend:(EWPerson *)person completion:(void (^)(EWFriendshipStatus status, NSError *error))completion;
- (void)acceptFriend:(EWPerson *)person __deprecated;//use - (void)acceptFriend:(EWPerson *)person completion:(void (^)(EWFriendshipStatus status, NSError *error))completion;
- (void)unfriend:(EWPerson *)person __deprecated;//use - (void)unfriend:(EWPerson *)person completion:(BoolErrorBlock)completion;
- (float)distance;
- (NSString *)distanceString;

@end
