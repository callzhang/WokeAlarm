#import "EWServerObject.h"


@interface EWServerObject ()

// Private interface goes here.

@end


@implementation EWServerObject
- (BOOL)validate{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return NO;
}

- (void)remove{
    [self MR_deleteEntity];
    [EWSync save];
}

- (NSString *)serverID{
    return self.objectId;
}

- (void)updateToServerWithCompletion:(PFObjectResultBlock)block{
    if (!self.objectId) {
        //create save block
        PFObjectResultBlock resultBlock = ^(PFObject *object, NSError *error) {
            block(object, error);
        };
        //add sync block
        [[EWSync sharedInstance] addSaveCallback:resultBlock forManagedObjectID:self.objectID];
        //save
        [EWSync save];
    }else{
        if (block) {
            block(self.parseObject, nil);
        }
    }
}

@end
