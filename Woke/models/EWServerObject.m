#import "EWServerObject.h"


@interface EWServerObject ()

// Private interface goes here.

@end


@implementation EWServerObject
@dynamic syncInfo;

- (void)awakeFromInsert{
	[super awakeFromInsert];
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
    DDLogDebug(@"---> Deleted MO %@(%@)", self.entity.name, self.serverID);
    NSManagedObjectID *selfID = self.objectID;
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kManagedObjectDeleted object:selfID];
	});
    [EWSync removeMOFromUpdating:self];
    
    NSManagedObjectContext *context = self.managedObjectContext;
	//[self.parseObject unpin];//no need to unpin, it will be deleted later
    [self MR_deleteEntity];
    [context MR_saveToPersistentStoreAndWait];
}

- (void)save{
    if ([NSThread isMainThread]) {
        [self.managedObjectContext MR_saveToPersistentStoreAndWait];
    }
    else{
        DDLogVerbose(@"Skip saving %@(%@) on background thread", self.entity.name, self.serverID);
    }
}


- (NSString *)serverID{
    return self.objectId;
}
@end
