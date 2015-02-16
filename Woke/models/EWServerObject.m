#import "EWServerObject.h"


@interface EWServerObject ()

// Private interface goes here.

@end


@implementation EWServerObject
@dynamic syncInfo;

- (void)awakeFromInsert{
    [self setPrimitiveValue:[NSMutableDictionary new] forKey:EWServerObjectAttributes.syncInfo];
    [self setPrimitiveValue:[NSDate date] forKey:EWServerObjectAttributes.createdAt];
    //Do not set updatedAt as this value is used to determine if object is updated properly
    //[self setPrimitiveValue:[NSDate date] forKey:EWServerObjectAttributes.updatedAt];
}


- (BOOL)validate{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return NO;
}

- (void)remove{
    NSManagedObjectContext *context = self.managedObjectContext;
    [self MR_deleteEntity];
    if ([NSThread isMainThread]) {
        [context MR_saveToPersistentStoreAndWait];
    }
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
    }
    else{
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

- (void)updateToServerWithCompletion:(EWManagedObjectSaveCallbackBlock)block{
    [[EWSync sharedInstance].MOSaveCallbacks setObject:block forKey:self.objectID.URIRepresentation.absoluteString];
    [self save];
    if (!self.hasChanges) {
        DDLogWarn(@"MO %@(%@) passed in for update has no changes", self.entity.name, self.serverID);
    }
}

- (EWServerObject *)ownerObject{
    return nil;
}

@end
