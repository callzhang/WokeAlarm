#import "EWServerObject.h"


@interface EWServerObject ()

// Private interface goes here.

@end


@implementation EWServerObject
- (BOOL)validate{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return NO;
}

- (NSString *)serverID{
    return self.objectId;
}

@end
