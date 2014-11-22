//
//  EWPerson.h
//  EarlyWorm
//
//  Created by Lei on 10/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "_EWPerson.h"
#import <Parse/Parse.h>

@import CoreLocation;

@class EWAlarm;

extern NSString * const EWPersonDefaultName;

@interface EWPerson : _EWPerson
@property (nonatomic, strong) CLLocation* lastLocation;
@property (nonatomic, strong) UIImage *profilePic;
@property (nonatomic, strong) UIImage *bgImage;
@property (nonatomic, strong) NSDictionary *preference;
@property (nonatomic, strong) NSDictionary *cachedInfo;
@property (nonatomic, strong) NSArray *images;

+ (EWPerson *)me;
- (BOOL)isMe;
- (BOOL)isFriend;
- (BOOL)friendPending;
- (BOOL)friendWaiting;
- (NSString *)genderObjectiveCaseString;

- (BOOL)validate;

//my stuff
+ (NSArray *)myActivities;
+ (NSArray *)myNotifications;
+ (NSArray *)myUnreadNotifications;
//+ (void)getFriendsForPerson:(EWPerson *)person;

+ (NSArray *)myAlarms;
+ (EWAlarm *)myNextAlarm;
+ (NSArray *)myFriends;

//friend
+ (void)requestFriend:(EWPerson *)person;
+ (void)acceptFriend:(EWPerson *)person;
+ (void)unfriend:(EWPerson *)person;
+ (void)updateMyCachedFriends;

+ (EWPerson *)findOrCreatePersonWithParseObject:(PFUser *)user;
@end
