#import "EWSocial.h"

@interface EWSocial ()

// Private interface goes here.

@end

@implementation EWSocial
@dynamic addressBookFriends;
@dynamic addressBookRelatedUsers;
@dynamic facebookFriends;
@dynamic friendshipTimeline;

// Custom logic goes here.

- (void)awakeFromInsert{
    [super awakeFromInsert];
    self.facebookFriends = [NSMutableDictionary new];
    self.addressBookFriends = [NSMutableArray new];
    self.addressBookRelatedUsers = [NSMutableArray new];
}


+ (instancetype)newSocialForPerson:(EWPerson *)person{
	EWSocial *sg = [EWSocial MR_createEntityInContext:person.managedObjectContext];
	sg.updatedAt = [NSDate date];
	
	//data
	sg.owner = person;
    
	//save
	[sg save];
	DDLogVerbose(@"Created new social graph for user %@", person.name);
	return sg;
}

+ (instancetype)getSocialByID:(NSString *)socialID error:(NSError *__autoreleasing *)error{
    EWAssertMainThread
    EWSocial *social = (EWSocial *)[EWSync findObjectWithClass:NSStringFromClass(self) withID:socialID error:error];
    if (!social) {
        DDLogError((*error).description);
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
