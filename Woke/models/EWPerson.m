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
- (void)awakeFromInsert{
    [super awakeFromInsert];
    [self setPrimitiveValue:[NSMutableDictionary new] forKey:EWPersonAttributes.preference];
	//we should not set default value for those who would be synced as PFFile, as they will be regarded as downloaded
    //[self setPrimitiveValue:[ImagesCatalog profileSlice] forKey:EWPersonAttributes.profilePic];
    //[self setPrimitiveValue:[[CLLocation alloc] initWithLatitude:0 longitude:0] forKey:EWPersonAttributes.location];
}

+ (EWPerson *)findOrCreatePersonWithParseObject:(PFUser *)user{
    EWPerson *person = (EWPerson *)[user managedObjectInContext:mainContext];
    if (user.isNew || !user[@"name"]) {
        DDLogInfo(@"New user signed up, assign default value");
        person.name = kDefaultUsername;
        person.preference = kUserDefaults;
        //person.updatedAt = [NSDate date];
    }
    
    //no need to save here
    return person;
}

#pragma mark - Helper
- (NSString *)genderObjectiveCaseString {
    return [self.gender isEqualToString:@"male"]?@"he":@"she";
}

- (NSString *)genderSubjectiveCaseString {
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
    if(!self.firstName){
        DDLogError(@"name is missing for user %@", self);
        good = NO;
    }
    if(!self.profilePic){
        DDLogError(@"Missing profile pic for user %@", self);
        good = NO;
    }
    if(!self.username){
        good = NO;
        //self.username = [PFUser currentUser].username;
        DDLogError(@"Username is missing for user %@", self);
    }
    
    if (self.alarms.count != 7 && self.isMe) {
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

- (NSString *)facebookID{
    PFObject *user = self.parseObject;
    NSString *ID = [user valueForKeyPath:@"authData.facebook.id"];
    return ID;
}

@end