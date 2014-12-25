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

- (void)updateToServerWithCompletion:(void (^)(PFObject *PO))block{
    if (!self.objectId) {
        [EWSync saveWithCompletion:^{
            NSAssert(self.objectId, @"MO doesn't have an objectId after server update");
            PFObject *PO = self.parseObject;
            if (block) {
                block(PO);
            }
        }];
    }else{
        if (block) {
            block(self.parseObject);
        }
    }
    
}

@end
