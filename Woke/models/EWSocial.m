#import "EWSocial.h"

@interface EWSocial ()

// Private interface goes here.

@end

@implementation EWSocial
@dynamic addressBookFriends;
@dynamic facebookFriends;
@dynamic friendshipTimeline;
// Custom logic goes here.

- (BOOL)validate{
    BOOL good = YES;
    if (!self.facebookID || !self.weiboID) {
        good = NO;
    }
    return good;
}

@end
