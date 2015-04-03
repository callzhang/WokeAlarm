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
#import "EWSync.h"

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
        person.preference = kUserDefaults;
        person.statement = @"Someone wake me up!";
        //name should not be assigned here
        person.updatedAt = [NSDate dateWithTimeIntervalSince1970:0];
        person.cachedInfo = [NSDictionary new];
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
    
    BOOL good = YES;
    NSParameterAssert(self.serverID);
    NSParameterAssert(self.updatedAt);
    //NSParameterAssert(self.firstName);
    NSParameterAssert(self.username);
    NSParameterAssert(self.cachedInfo);
    if(!self.profilePic){
        DDLogError(@"Missing profile pic for user %@", self.name);
        good = NO;
    }
	
	//check me
	if (self.isMe) {
		if (self.alarms.count != 7) {
			good = NO;
			DDLogError(@"The person failed validation: alarms: %ld", (long)self.alarms.count);
        }
        NSParameterAssert(self.preference);
        NSParameterAssert(self.socialProfileID);
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
    NSString *ID = self.socialProfileID;
    if ([ID hasPrefix:kFacebookIDPrefix]) {
        ID = [ID substringFromIndex:[kFacebookIDPrefix length]];
        return ID;
    }
    return nil;
}

@end