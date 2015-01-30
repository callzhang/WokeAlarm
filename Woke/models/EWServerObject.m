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
    NSManagedObjectContext *context = self.managedObjectContext;
    [self MR_deleteEntity];
    [context MR_saveToPersistentStoreWithCompletion:NULL];
}

- (NSString *)serverID{
    return self.objectId;
}

- (NSString *)serverClassName{
	return self.entity.name;
}

- (void)save{
    if (self.updated && self.updatedAt) {
        self.updatedAt = [NSDate date];
    }
    
    if ([NSThread isMainThread]) {
        [self.managedObjectContext MR_saveToPersistentStoreAndWait];
    }else{
        DDLogVerbose(@"Skip saving %@(%@) on background thread", self.entity.name, self.serverID);
    }
}

- (void)saveWithCompletion:(BoolErrorBlock)block{
    if (self.updated && self.updatedAt) {
        self.updatedAt = [NSDate date];
    }
	[self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
		if (block) {
			block(contextDidSave, error);
		}
	}];
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
        [self save];
    }
    else if(self.changedKeys.count){
        [EWSync saveWithCompletion:^{
            if (block) {
                block(self.parseObject, nil);
            }
        }];
    }
    else{
        if (block) {
            block(self.parseObject, nil);
        }
    }
}

- (EWServerObject *)ownerObject{
    return nil;
}

@end
