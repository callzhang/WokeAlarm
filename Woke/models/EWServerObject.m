#import "EWServerObject.h"


@interface EWServerObject ()

// Private interface goes here.

@end


@implementation EWServerObject
- (BOOL)validate{
    NSParameterAssert(NO);
    return NO;
}

- (NSString *)serverID{
    return self.objectId;
}

@end
