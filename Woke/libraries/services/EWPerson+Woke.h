//
//  EWPerson(Woke).h
//  Woke
//
//  Created by Lei Zhang on 11/28/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWPerson.h"

@interface EWPerson(Woke)
+ (EWPerson *)me;
- (BOOL)isMe;

//my stuff
+ (NSArray *)myActivities;
+ (NSArray *)myNotifications;
+ (NSArray *)myUnreadNotifications;
+ (NSArray *)myAlarms;
+ (EWAlarm *)myNextAlarm;
+ (NSArray *)myFriends;
+ (NSArray *)alarmsForUser:(EWPerson *)user;


//Tools
+ (void)updateMeFromFacebook;
@end
