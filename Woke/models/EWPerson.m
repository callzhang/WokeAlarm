//
//  EWPerson.m
//  EarlyWorm
//
//  Created by Lei on 10/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//j

#import "EWPerson.h"
#import "EWPersonManager.h"
#import "EWAccountManager.h"
#import "EWPerson+Woke.h"
#import "EWCachedInfoManager.h"
#import "FBKVOController.h"

NSString * const EWPersonDefaultName = @"New User";

@implementation EWPerson
@dynamic location;
@dynamic profilePic;
@dynamic bgImage;
@dynamic preference;
@dynamic cachedInfo;
@dynamic images;
@synthesize name;

#pragma mark - Create
+ (EWPerson *)findOrCreatePersonWithParseObject:(PFUser *)user{
    EWPerson *person = (EWPerson *)[user managedObjectInContext:mainContext];
    if (user.isNew || !user[@"name"]) {
        DDLogInfo(@"New user signed up, assign default value");
        person.name = kDefaultUsername;
        person.preference = kUserDefaults;
        person.cachedInfo = [NSDictionary new];
        //person.updatedAt = [NSDate date];
        
        [[EWAccountManager shared] updateMyFacebookInfo];
    }
    
    //no need to save here
    return person;
}

#pragma mark - Helper
- (NSString *)genderObjectiveCaseString {
    return [self.gender isEqualToString:@"male"]?@"him":@"her";
}

- (NSString *)name{
    return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}

#pragma mark - Validation
- (BOOL)validate{
    if (!self.isMe) {
        //skip check other user
        return YES;
    }
    
    BOOL good = YES;
    if (!self.serverID) {
        good = NO;
    }
    if(!self.name){
        NSString *name_ = [PFUser currentUser][@"name"];
        if (name_) {
            self.name = name_;
        }else{
            good = NO;
        }
    }
    if(!self.profilePic){
        PFFile *pic = [PFUser currentUser][@"profilePic"];
        UIImage *img = [UIImage imageWithData:pic.getData];
        if (img) {
            self.profilePic = img;
        }else{
            good = NO;
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
    
    //preference
    if (!self.preference) {
        self.preference = kUserDefaults;
    }
    
    return good;
}

- (NSString *)serverClassName{
	return @"_User";
}

- (EWServerObject *)ownerObject{
    return self;
}

- (void)awakeFromFetch{
    if([NSThread isMainThread] && self.isMe){
        [self.KVOController observe:self keyPath:EWPersonRelationships.socialGraph options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld block:^(id observer, id object, NSDictionary *change) {
            EWSocial *oldS = change[NSKeyValueChangeOldKey];
            EWSocial *newS = change[NSKeyValueChangeNewKey];
            if (oldS != newS && newS == nil) {
                DDLogWarn(@"Social just changed from %@ to %@", oldS, newS);
            }
        }];
    }
}
@end