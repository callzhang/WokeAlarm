#import "EWSocial.h"

@interface EWSocial ()

// Private interface goes here.

@end

@implementation EWSocial
@dynamic addressBookFriends;
@dynamic addressBookRelatedUsers;
@dynamic facebookFriends;
@dynamic facebookRelatedUsers;
@dynamic friendshipTimeline;

// Custom logic goes here.
+ (instancetype)newSocialForPerson:(EWPerson *)person{
	EWSocial *sg = [EWSocial MR_createEntityInContext:person.managedObjectContext];
	sg.updatedAt = [NSDate date];
	
	//data
	sg.owner = person;
    sg.facebookRelatedUsers = [NSMutableArray new];
    sg.facebookFriends = [NSMutableDictionary new];
    sg.addressBookFriends = [NSMutableArray new];
    sg.addressBookRelatedUsers = [NSMutableArray new];
    
	//save
	[sg save];
	DDLogVerbose(@"Created new social graph for user %@", person.name);
	return sg;
}

+ (instancetype)getSocialByID:(NSString *)socialID{
    EWAssertMainThread
    NSError *error;
    EWSocial *social = (EWSocial *)[EWSync findObjectWithClass:NSStringFromClass(self) withID:socialID error:&error];
    if (error) {
        DDLogError(error.description);
    }
    return social;
}

- (BOOL)validate{
    BOOL good = YES;
    if (!self.facebookID) {
        good = NO;
    }
    
    return good;
}

- (EWServerObject *)ownerObject{
    return self.owner;
}

@end
