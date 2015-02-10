#import "EWFriendRequest.h"

NSString * const EWFriendshipRequestDenied = @"friend_request_denied";
NSString * const EWFriendshipRequestPending = @"friend_request_pending";
NSString * const EWFriendshipRequestFriended = @"friend_request_friended";


@interface EWFriendRequest ()

// Private interface goes here.

@end

@implementation EWFriendRequest
- (BOOL)validate{
    BOOL good = YES;
    if (!self.sender) {
        DDLogError(@"Missing sender %@", self.serverID);
    }
    
    if (!self.receiver) {
        DDLogError(@"Missing receiver %@", self.serverID);
    }
    
    if (!self.status) {
        DDLogError(@"Missing status %@", self.serverID);
    }
    
    return good;
}

- (EWPerson *)owner{
    if (self.sender == [EWPerson me]) {
        return self.sender;
    }else if (self.receiver == [EWPerson me]){
        return self.receiver;
    }
    
    return nil;
}
@end
