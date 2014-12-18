//
//  EWPerson.m
//  EarlyWorm
//
//  Created by Lei on 10/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//j

#import "EWPerson.h"
#import "EWPersonManager.h"
#import "EWNotificationManager.h"
#import "EWAccountManager.h"
#import "EWCachedInfoManager.h"
#import "EWAlarm.h"
#import "EWAlarmManager.h"
#import "EWActivityManager.h"

NSString * const EWPersonDefaultName = @"New User";

@implementation EWPerson
@dynamic lastLocation;
@dynamic profilePic;
@dynamic bgImage;
@dynamic preference;
@dynamic cachedInfo;
@dynamic images;


#pragma mark - Helper methods


-(BOOL)isFriend {
    BOOL myFriend = self.friendPending;
    BOOL friended = self.friendWaiting;
    
    if (myFriend && friended) {
        return YES;
    }
    return NO;
}

//request pending
- (BOOL)friendPending {
    return [[EWPerson me].cachedInfo[kCachedFriends] containsObject:self.objectId];
}

//wait for friend acceptance
- (BOOL)friendWaiting {
    return [self.cachedInfo[kCachedFriends] containsObject:[EWPerson me].objectId];
}

- (NSString *)genderObjectiveCaseString {
    NSString *str = [self.gender isEqualToString:@"male"]?@"him":@"her";
    return str;
}


+ (void)requestFriend:(EWPerson *)person{
    [[EWPerson me] addFriendsObject:person];
    [EWPerson updateMyCachedFriends];
    [EWNotificationManager sendFriendRequestNotificationToUser:person];
    
    [EWSync save];
}

+ (void)acceptFriend:(EWPerson *)person{
    [[EWPerson me] addFriendsObject:person];
    [EWPerson updateMyCachedFriends];
    [EWNotificationManager sendFriendAcceptNotificationToUser:person];
    
    [EWSync save];
}

+ (void)unfriend:(EWPerson *)person{
    [[EWPerson me] removeFriendsObject:person];
    [EWPerson updateMyCachedFriends];
    [EWSync save];
}

+ (void)updateMyCachedFriends{
    [[EWPerson me] updateMyFriends];
}

- (void)updateMyFriends {
    NSArray *friendsCached = self.cachedInfo[kCachedFriends]?:[NSArray new];
    NSSet *friends = self.friends;
    BOOL friendsNeedUpdate = self.isMe && friendsCached.count !=self.friends.count;
    if (!friends || friendsNeedUpdate) {
        
        DDLogInfo(@"Friends mismatch, fetch from server");
        
        //friend need update
        PFQuery *q = [PFQuery queryWithClassName:self.serverClassName];
        [q includeKey:@"friends"];
        [q whereKey:kParseObjectID equalTo:self.serverID];
        PFObject *user = [[EWSync findServerObjectWithQuery:q] firstObject];
        NSArray *friendsPO = user[@"friends"];
        if (friendsPO.count == 0) return;//prevent 0 friend corrupt data
        NSMutableSet *friendsMO = [NSMutableSet new];
        for (PFObject *f in friendsPO) {
            if ([f isKindOfClass:[NSNull class]]) {
                continue;
            }
            EWPerson *mo = (EWPerson *)[f managedObjectInContext:self.managedObjectContext];
            [friendsMO addObject:mo];
        }
        self.friends = [friendsMO copy];
        if (self.isMe) {
            [EWPerson updateMyCachedFriends];
        }
    }
}


#pragma mark - Parsed
+ (EWPerson *)findOrCreatePersonWithParseObject:(PFUser *)user{
    EWPerson *person = (EWPerson *)[user managedObjectInContext:mainContext];
    if (user.isNew || !user[@"name"]) {
        DDLogInfo(@"New user logged in, assign new value");
        person.name = kDefaultUsername;
        person.preference = kUserDefaults;
        person.cachedInfo = [NSDictionary new];
        person.updatedAt = [NSDate date];
        
        [[EWAccountManager shared] updateMyFacebookInfo];
    }
    
    //no need to save here
    return person;
}


#pragma mark - Validation
- (BOOL)validate{
    if (!self.isMe) {
        //skip check other user
        return YES;
    }
    
    BOOL good = YES;
    BOOL needRefreshFacebook = NO;
    if(!self.name){
        NSString *name = [PFUser currentUser][@"name"];
        if (name) {
            self.name = name;
        }else{
            needRefreshFacebook = YES;
        }
    }
    if(!self.profilePic){
        PFFile *pic = [PFUser currentUser][@"profilePic"];
        UIImage *img = [UIImage imageWithData:pic.getData];
        if (img) {
            self.profilePic = img;
        }else{
            needRefreshFacebook = YES;
        }
    }
    if(!self.username){
        self.username = [PFUser currentUser].username;
        DDLogError(@"Username is missing!");
    }
    
    if (self.alarms.count == 7) {
        good = YES;
    }else{
        good = NO;
        DDLogError(@"The person failed validation: alarms: %ld", (long)self.alarms.count);
    }
    
    if (needRefreshFacebook) {
        [[EWAccountManager shared] updateMyFacebookInfo];
    }
    
    //preference
    if (!self.preference) {
        self.preference = kUserDefaults;
    }
    
    //friends
    NSArray *friendsID = self.cachedInfo[kFriended];
    if (self.friends.count != friendsID.count) {
        [EWPerson updateMyCachedFriends];
    }
    
    return good;
}
@end


@implementation EWPerson(Woke)

#pragma mark - ME
+ (EWPerson *)me{
    if (![NSThread isMainThread]) {
        DDLogWarn(@"Me called on background thread");
    }
    return [EWSession sharedSession].currentUser;
}


- (BOOL)isMe {
    BOOL isme = NO;
    if ([EWPerson me]) {
        isme = [self.username isEqualToString:[EWPerson me].username];
    }
    return isme;
}


//FIXME: took too long, need to optimize, maybe use one server call.
//check my relation, used for new installation with existing user
+ (void)updateMe{
    NSDate *lastCheckedMe = [[NSUserDefaults standardUserDefaults] valueForKey:kLastCheckedMe];
    BOOL good = [[EWPerson me] validate];
    if (!good || !lastCheckedMe || lastCheckedMe.timeElapsed > kCheckMeInternal) {
        if (!good) {
            DDLogError(@"Failed to validate me, refreshing from server");
        }else if (!lastCheckedMe) {
            DDLogError(@"Didn't find lastCheckedMe date, start to refresh my relation in background");
        }else{
            DDLogError(@"lastCheckedMe date is %@, which exceed the check interval %d, start to refresh my relation in background", lastCheckedMe.date2detailDateString, kCheckMeInternal);
        }
        
        [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
            EWPerson *localMe = [[EWPerson me] MR_inContext:localContext];
            [localMe refreshRelatedWithCompletion:^{
                
                [localMe updateMyFriends];
                [[EWAccountManager shared] updateMyFacebookInfo];
            }];
            //TODO: we need a better sync method
            //1. query for medias
            
            
            //2. check
        }];
        
        
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:kLastCheckedMe];
    }
}


#pragma mark - My Stuffs

- (void)updateStatus:(NSString *)status completion:(void (^)(NSError *))completion {
    [[[self class] myAlarms] enumerateObjectsUsingBlock:^(EWAlarm *obj, NSUInteger idx, BOOL *stop) {
        obj.statement = status;
    }];
    
    [EWPerson me].statement = status;
    
    [EWSync saveWithCompletion:^{
        completion(nil);
    }];
}

+ (NSArray *)myActivities {
    NSArray *activities = [EWPerson me].activities.allObjects;
    return [activities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.updatedAt ascending:NO]]];
}

+ (NSArray *)myUnreadNotifications {
    NSArray *notifications = [self myNotifications];
    NSArray *unread = [notifications filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed == nil"]];
    return unread;
}

+ (NSArray *)myNotifications {
    NSArray *notifications = [[EWPerson me].notifications allObjects];
    NSSortDescriptor *sortCompelet = [NSSortDescriptor sortDescriptorWithKey:@"completed" ascending:NO];
    NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO];
    NSSortDescriptor *sortImportance = [NSSortDescriptor sortDescriptorWithKey:@"importance" ascending:NO];
    notifications = [notifications sortedArrayUsingDescriptors:@[sortCompelet,sortImportance, sortDate]];
    return notifications;
}

+ (NSArray *)myAlarms {
    NSParameterAssert([NSThread isMainThread]);
    return [[EWAlarmManager sharedInstance] alarmsForPerson:[EWPerson me]];
}

+ (EWAlarm *)myCurrentAlarm {
    EWAlarm *next = [[EWAlarmManager sharedInstance] nextAlarmForPerson:[self me]];
    return next;
}

+ (EWActivity *)myCurrentAlarmActivity{
    EWActivity *activity = [[EWActivityManager sharedManager] myCurrentAlarmActivity];
    return activity;
}

+ (NSArray *)myFriends{
    return [EWPerson me].friends.allObjects;
}
@end
