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

//validate
- (BOOL)validate;

//helper
- (BOOL)isFriend;
- (BOOL)friendPending;
- (BOOL)friendWaiting;
- (NSString *)genderObjectiveCaseString;
+ (void)updateMyCachedFriends;

//friend
+ (void)requestFriend:(EWPerson *)person;
+ (void)acceptFriend:(EWPerson *)person;
+ (void)unfriend:(EWPerson *)person;
/**
 *  Find or create EWPerson from PFUser
 *
 *  @param user PFUser
 *  @discussion If PFUser isNew or missing name, it will trigger new user sequence and assign default value
 *  @return EWPerson
 */
+ (EWPerson *)findOrCreatePersonWithParseObject:(PFUser *)user;
@end


@interface EWPerson(Woke)
+ (EWPerson *)me;
- (BOOL)isMe;

//my stuff
+ (NSArray *)myActivities;
+ (NSArray *)myNotifications;
+ (NSArray *)myUnreadNotifications;
+ (NSArray *)myAlarms;
+ (NSArray *)myFriends;

- (void)updateStatus:(NSString *)status completion:(void (^)(NSError *error))completion;

+ (EWAlarm *)myCurrentAlarm;
+ (EWActivity *)myCurrentAlarmActivity;

@end
