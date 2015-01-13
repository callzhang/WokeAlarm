#import "EWSocial.h"

@interface EWSocial ()

// Private interface goes here.

@end

@implementation EWSocial
@dynamic addressBookFriends;
@dynamic facebookFriends;
@dynamic friendshipTimeline;
// Custom logic goes here.

+ (instancetype)newSocialForPerson:(EWPerson *)person{
	EWSocial *sg = [EWSocial MR_createEntityInContext:person.managedObjectContext];
	sg.updatedAt = [NSDate date];
	
	//data
	sg.owner = person;
	//save
	[sg save];
	NSLog(@"Created new social graph for user %@", person.name);
	return sg;
}

- (BOOL)validate{
    BOOL good = YES;
    if (!self.facebookID && !self.weiboID) {
        good = NO;
    }
    return good;
}

@end
