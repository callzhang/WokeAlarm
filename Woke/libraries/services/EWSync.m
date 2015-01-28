//
//  EWSync.m
//  Woke
//
//  Created by Lee on 9/24/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "EWSync.h"
#import "EWUIUtil.h"
#import "EWServerObject.h"
#import "AFNetworkReachabilityManager.h"
#import <WellCached/ELAWellCached.h>
#import "NSDictionary+KeyPathAccess.h"

//============ Global shortcut to main context ===========
NSManagedObjectContext *mainContext;
//=======================================================

@interface EWSync()
@property NSManagedObjectContext *context; //the main context(private)
@property NSMutableDictionary *parseSaveCallbacks;
@property (nonatomic) NSTimer *saveToServerDelayTimer;
@property AFNetworkReachabilityManager *reachability;
@end


@implementation EWSync
@synthesize parseSaveCallbacks;
@synthesize isUploading = _isUploading;

+ (EWSync *)sharedInstance{
    
    static EWSync *sharedInstance_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance_ = [[EWSync alloc] init];
    });
    return sharedInstance_;
}

- (void)setup{
    
    //server: enable alert when offline
    [Parse errorMessagesEnabled:YES];
    
    //Access Control: enable public read access while disabling public write access.
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    //core data
    [MagicalRecord setupCoreDataStack];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelWarn];
    _context = [NSManagedObjectContext MR_defaultContext];
    mainContext = _context;
    
    //observe context change to update the modifiedData of that MO. (Only observe the main context)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preSaveAction:) name:NSManagedObjectContextWillSaveNotification object:_context];
    
    //Observe background context saves so main context can perform upload
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:_context queue:nil usingBlock:^(NSNotification *note) {
        [_saveToServerDelayTimer invalidate];
        _saveToServerDelayTimer = [NSTimer scheduledTimerWithTimeInterval:kUploadLag target:self selector:@selector(uploadToServer) userInfo:nil repeats:NO];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:EWAccountDidLogoutNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueRefresh];

    }];
    
    //Reachability
    self.reachability = [AFNetworkReachabilityManager sharedManager];
    [self.reachability startMonitoring];
    [self.reachability setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status != 0) {
            DDLogDebug(@"====== Network is reachable. Start upload. ======");
            //in background thread
            [[EWSync sharedInstance] resumeUploadToServer];
            
            //resume refresh MO
            NSSet *MOs = [[EWSync sharedInstance] getObjectFromQueue:kParseQueueRefresh];
            for (EWServerObject *MO in MOs) {
                [MO refreshInBackgroundWithCompletion:^(NSError *error){
                    DDLogInfo(@"%@(%@) refreshed after network resumed: %@", MO.entity.name, MO.serverID, error.description);
                }];
            }
        } else {
            DDLogInfo(@"====== Network is unreachable ======");
        }
        
    }];
    
    //initial property
    self.parseSaveCallbacks = [NSMutableDictionary dictionary];
    self.saveCallbacks = [NSMutableArray new];
    self.saveToLocalItems = [NSMutableArray new];
    self.serverObjectCache = [ELAWellCached cacheWithDefaultExpiringDuration:kCacheLifeTime];
	
}


#pragma mark - connectivity
+ (BOOL)isReachable{
    return [EWSync sharedInstance].isReachable;
}

- (BOOL)isReachable{
    return !self.reachability.networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable;
}

#pragma mark - ============== Parse Server methods ==============
- (BOOL)isUploading{
    return _isUploading;
}

- (void)setIsUploading:(BOOL)isUploading{
    @synchronized(self){
        _isUploading = isUploading;
    }
}

- (void)uploadToServer{
    //make sure it is called on main thread
    EWAssertMainThread
    if([mainContext hasChanges]){
        DDLogDebug(@"There is still some change, save and do it later");
        [mainContext MR_saveToPersistentStoreAndWait];
        return;
    }
    
    if ([self workingQueue].count >0 && self.isUploading) {
        DDLogWarn(@"Data Store is uploading, delay for 10s: %@", self.updatingClassAndValues);
        static NSTimer *uploadDelay;
        [uploadDelay invalidate];
        uploadDelay = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(uploadToServer) userInfo:nil repeats:NO];
        return;
    }
    self.isUploading = YES;
    
    //determin network reachability
    if (!self.isReachable) {
        DDLogDebug(@"Network not reachable, skip uploading");
        [self runCompletionBlocks:self.saveCallbacks];
        return;
    }
    
    //only ManagedObjectID is thread safe
    NSSet *insertedManagedObjects = [self insertQueue];
    NSSet *updatedManagedObjects = [self updateQueue];
    NSSet *deletedServerObjects = self.deleteQueue;
    
    //copy the list to working queue
    for (EWServerObject *mo in insertedManagedObjects) [self appendObject:mo toQueue:kParseQueueWorking];
    for (EWServerObject *mo in updatedManagedObjects) [self appendObject:mo toQueue:kParseQueueWorking];
    //clear queues
    [self clearQueue:kParseQueueInsert];
    [self clearQueue:kParseQueueUpdate];
    
    //save to local items check
    NSSet *workingObjects = self.workingQueue.copy;
    NSArray *saveToLocalItemAlreadyInWorkingQueue = [self.saveToLocalItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", [workingObjects valueForKey:@"objectID"]]];
    if (saveToLocalItemAlreadyInWorkingQueue.count) {
        DDLogError(@"There are items in saveToLocal queue but also appeared in working queue, please check the code!%@", saveToLocalItemAlreadyInWorkingQueue);
        for (NSManagedObjectID *ID in saveToLocalItemAlreadyInWorkingQueue) {
            [self.saveToLocalItems removeObject:ID];
        }
    }
    
	
	//skip if no changes
    if (workingObjects.count == 0 && deletedServerObjects.count == 0){
        DDLogInfo(@"No change detacted, skip uploading");
        [self runCompletionBlocks:self.saveCallbacks];
        return;
    }
    
    //logging
    DDLogInfo(@"============ Start updating to server =============== \n Inserts:%@, \n Updates:%@ \n and Deletes:%@ ", [insertedManagedObjects valueForKeyPath:@"entity.name"], self.updatingClassAndValues, deletedServerObjects);
    
    //save callbacks
    NSArray *callbacks = [self.saveCallbacks copy];
    [_saveCallbacks removeAllObjects];
    
    //start background update
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (EWServerObject *MO in workingObjects) {
            EWServerObject *localMO = [MO MR_inContext:localContext];
            if (!localMO) {
                DDLogVerbose(@"*** MO %@(%@) to upload haven't saved", MO.entity.name, MO.serverID);
                continue;
            }
			
			//validation
			if (![EWSync validateSO:localMO]) {
				DDLogWarn(@"!!! Validation failed for %@(%@), skip upload. Detail: \n%@", localMO.entity.name, localMO.serverID, localMO);
				return;
			}
			//=================>> Upload method <<===================
            [self updateParseObjectFromManagedObject:localMO];
            //=======================================================
            
            //remove changed record
            NSMutableSet *changes = self.changedRecords[localMO.serverID];
			self.changedRecords = [self.changedRecords setValue:nil forImmutableKeyPath:@[localMO.serverID]];
            DDLogVerbose(@"===> MO %@(%@) uploaded to server with changes applied: %@. %lu to go.", localMO.entity.name, localMO.serverID, changes, (unsigned long)self.changedRecords.allKeys.count);
            
            //remove from queue
            [self removeObjectFromWorkingQueue:localMO];
        }
        
        for (PFObject *po in deletedServerObjects) {
            [self deleteParseObject:po];
        }
        
    } completion:^(BOOL success, NSError *error) {
        
        DDLogVerbose(@"=========== Finished uploading to saver ===============");
        [self runCompletionBlocks:callbacks];
        
    }];
}

- (void)runCompletionBlocks:(NSArray *)callbacks{
    //TODO: use object-specific block as callback block
    if (callbacks.count) {
        DDLogVerbose(@"=========== Start running completion block (%lu) =============", (unsigned long)callbacks.count);
        for (EWSavingCallback block in callbacks){
            block();
        }
    }
    
    NSSet *remainningWorkingObjects = self.workingQueue;
    if (remainningWorkingObjects.count > 0) {
        DDLogInfo(@"*** With remainning working objects: (ID)%@ (Entity)%@", [remainningWorkingObjects valueForKey:@"objectId"], [remainningWorkingObjects valueForKeyPath: @"entity.name"]);
        [self resumeUploadToServer];
    }
    
    self.isUploading = NO;
}

- (void)resumeUploadToServer{
    NSMutableSet *workingMOs = self.workingQueue.mutableCopy;
    [workingMOs unionSet:self.updateQueue];
    [workingMOs unionSet:self.insertQueue];
    NSSet *deletePOs = [self deleteQueue];
    if (workingMOs.count > 0 || deletePOs.count > 0) {
        DDLogInfo(@"There are %lu MOs need to upload or %lu MOs need to delete, resume uploading!", (unsigned long)workingMOs.count, (unsigned long)deletePOs.count);
        [self uploadToServer];
    }else{
        DDLogWarn(@"Nothing to resume uploading");
    }
}

//observe main context
- (void)preSaveAction:(NSNotification *)notification{
    EWAssertMainThread
    
    NSManagedObjectContext *localContext = (NSManagedObjectContext *)[notification object];
    
    [self enqueueChangesInContext:localContext];
}

- (void)enqueueChangesInContext:(NSManagedObjectContext *)context{
    //BOOL hasChange = NO;
    NSSet *updatedObjects = context.updatedObjects;
    NSSet *insertedObjects = context.insertedObjects;
    NSSet *deletedObjects = context.deletedObjects;
	NSMutableSet *objects = updatedObjects.mutableCopy;
	[objects unionSet:insertedObjects];
	[objects minusSet:deletedObjects];
    
    //for updated mo
    for (EWServerObject *SO in objects) {
        //check if it's our guy
        if (![SO isKindOfClass:[EWServerObject class]]) {
            continue;
        }
        //First test MO exist
        if (![context existingObjectWithID:SO.objectID error:NULL]) {
            DDLogError(@"*** MO you are trying to modify doesn't exist in the sqlite: %@", SO.objectID);
            continue;
        }
        
        //skip if marked save to local
        if ([self.saveToLocalItems containsObject:SO.objectID]) {
			NSUInteger index = [self.saveToLocalItems indexOfObject:SO.objectID];
			[self.saveToLocalItems removeObjectAtIndex:index];
            [self removeObjectFromInsertQueue:SO];
            [self removeObjectFromUpdateQueue:SO];
            continue;
        }
		
		//Pre-save validate
		if (![EWSync validateSO:SO]) {
			continue;
		}
		
        //check ACL
        if (![EWSync checkAccess:SO]) {
            DDLogWarn(@"!!! Skip uploading object with no access rights %@ with changes %@", SO.serverID, SO.changedKeys);
            continue;
        }
        
        if ([insertedObjects containsObject:SO] || !SO.objectId) {
            //enqueue to insertQueue
            [self appendInsertQueue:SO];
            
            //*** we should not add updatedAt here, as it is the criteria for enqueue. Two Inserts could be possible: downloaded from server or created here. Therefore we need to add createdAt at local creation point.
            //change updatedAt
            //[MO setValue:[NSDate date] forKeyPath:kUpdatedDateKey];
            continue;
        }
        
        //additional check for updated object
        if ([updatedObjects containsObject:SO]) {
            NSParameterAssert(SO.objectId);
            //check if updated keys exist
            NSMutableArray *changedKeys = SO.changedKeys.mutableCopy;
			[changedKeys removeObjectsInArray:attributeUploadSkipped];
            if (changedKeys.count > 0) {
                
                //add changed keys to record
				self.changedRecords = [self.changedRecords addValue:changedKeys toImmutableKeyPath:@[SO.objectId]];
				
                //add to queue
                [self appendUpdateQueue:SO];
                
                //change updatedAt: If MO already has updatedAt, then update the timestamp
                [SO setValue:[NSDate date] forKeyPath:kUpdatedDateKey];
            }
        }
    }
    
    for (EWServerObject *SO in deletedObjects) {
        //check if it's our guy
        if (![SO isKindOfClass:[EWServerObject class]]) continue;
        
        if (SO.serverID) {
            DDLogInfo(@"~~~> MO %@(%@) is going to be DELETED, enqueue PO to delete queue.", SO.entity.name, [SO valueForKey:kParseObjectID]);
            //get PO reference
            PFObject *PO = [PFObject objectWithoutDataWithClassName:SO.serverClassName objectId:SO.serverID];
            //remove PO from cache
            [self.serverObjectCache removeObjectForKey:SO.serverID];
            //add PO to delete queue
            [self appendObjectToDeleteQueue:PO];
        }
    }
}



#pragma mark - Upload worker
- (void)updateParseObjectFromManagedObject:(EWServerObject *)serverObject{
    NSError *error;
    
    //skip if updating other PFUser
    //make sure the value is the latest from store
    //[managedObject.managedObjectContext refreshObject:managedObject mergeChanges:NO];
    
    NSString *parseObjectId = serverObject.serverID;
    PFObject *object;
    if (parseObjectId) {
        //download
        object =[self getParseObjectWithClass:serverObject.serverClassName ID:parseObjectId error:&error];
        if ([object isNewerThanMO]) {
            DDLogWarn(@"The PO %@(%@) being updated from MO is newer than MO", object.parseClassName, object.objectId);
        }
        if (!object || error) {
            if ([error code] == kPFErrorObjectNotFound) {
                DDLogError(@"PO %@ couldn't be found!", serverObject.serverClassName);
                serverObject.objectId = nil;
            }
			else if ([error code] == kPFErrorConnectionFailed) {
                DDLogError(@"Uh oh, we couldn't even connect to the Parse Cloud!");
                [serverObject uploadEventually];
                return;
            }
			else if (error) {
                DDLogError(@"*** Error in getting related parse object from MO (%@). \n Error: %@", serverObject.entity.name, [error userInfo][@"error"]);
                [serverObject uploadEventually];
                return;
            }
            object = nil;
            error = nil;
        }
        
    }
    
    if (!object) {
        //insert
		if ([serverObject.entity.name isEqualToString:kSyncUserClass]) {
			DDLogError(@"Uploading user class, check your code!");
			return;
		}
        object = [PFObject objectWithClassName:serverObject.serverClassName];
        error = nil;
		[object save:&error];//need to save before working on PFRelation
		
        if (!error) {
            DDLogVerbose(@"+++> CREATED PO %@(%@)", object.parseClassName, object.objectId);
            [serverObject setValue:object.objectId forKey:kParseObjectID];
			//[managedObject setValue:object.updatedAt forKeyPath:kUpdatedDateKey];
        }
		else{
			DDLogError(@"Failed to save new PO %@", object.parseClassName);
            [serverObject uploadEventually];
            return;
        }
    }
    
    //==========set Parse value/relation and callback block===========
    [object updateFromManagedObject:serverObject];
    //================================================================
    
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *err) {
        if (err) {
            if (err.code == kPFErrorObjectNotFound){
                DDLogError(@"*** PO not found for %@(%@), set to nil.", serverObject.entity.name, serverObject.serverID);
                NSManagedObject *trueMO = [serverObject.managedObjectContext existingObjectWithID:serverObject.objectID error:NULL];
                if (trueMO) {
                    //need to check if the object is available
                    [serverObject setValue:nil forKey:kParseObjectID];
                }
            }
			else{
                DDLogError(@"*** Failed to save server object: %@", err.description);
            }
            [serverObject uploadEventually];
        }
		else{
            //assign connection between MO and PO
            [self performSaveCallbacksWithParseObject:object andManagedObjectID:serverObject.objectID];
        }
    }];
    
    //Time stamp for updated date. This is very important, otherwise MO will be outdated
	//Also if do not set kUpdateDateKey, means the relation haven't been downloaded yet.
	NSAssert(serverObject.serverID, @"serverID is nil");
	[serverObject setValue:[NSDate date] forKey:kUpdatedDateKey];
	[serverObject saveToLocal];
}

- (void)deleteParseObject:(PFObject *)parseObject{
	@try {
		[parseObject deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
			if (succeeded) {
				//Good
				DDLogVerbose(@"~~~> PO %@(%@) deleted from server", parseObject.parseClassName, parseObject.objectId);
			}
			else if (error.code == kPFErrorObjectNotFound){
				//fine
				DDLogWarn(@"~~~> Trying to deleted PO %@(%@) but not found", parseObject.parseClassName, parseObject.objectId);
			}
			else{
				//not good
				DDLogError(@"delete object failed, not sure why, %@(%@): error:%@", parseObject.parseClassName, parseObject.objectId, error);
			}
			
			[self removeObjectFromDeleteQueue:parseObject];
			[self.serverObjectCache removeObjectForKey:parseObject.objectId];
		}];
	}
	@catch (NSException *exception) {
		DDLogError(@"Error in deleting PO: %@, reason: %@", parseObject, exception.description);
		[self removeObjectFromDeleteQueue:parseObject];
		[self.serverObjectCache removeObjectForKey:parseObject.objectId];
	}
}


- (void)addSaveCallback:(PFObjectResultBlock)callback forManagedObjectID:(NSManagedObjectID *)objectID{
    //get global save callback
    NSMutableDictionary *saveCallbacks = self.parseSaveCallbacks;
    NSMutableArray *callbacks = [saveCallbacks objectForKey:objectID]?:[NSMutableArray array];
    [callbacks addObject:callback];
    //save
    [saveCallbacks setObject:callbacks forKey:objectID];
}


- (void)performSaveCallbacksWithParseObject:(PFObject *)parseObject andManagedObjectID:(NSManagedObjectID *)managedObjectID{
    NSArray *saveCallbacks = [self.parseSaveCallbacks objectForKey:managedObjectID];
    if (saveCallbacks) {
        for (PFObjectResultBlock callback in saveCallbacks) {
            NSError *err;
            callback(parseObject, err);
        }
        [self.parseSaveCallbacks removeObjectForKey:managedObjectID];
    }
}


#pragma mark - Server Updating Queue methods
//update queue
- (NSSet *)updateQueue{
    return [self getObjectFromQueue:kParseQueueUpdate];
}

- (void)appendUpdateQueue:(EWServerObject *)mo{
    //queue
    [self appendObject:mo toQueue:kParseQueueUpdate];
}

- (void)removeObjectFromUpdateQueue:(EWServerObject *)mo{
    [self removeObject:mo fromQueue:kParseQueueUpdate];
}

//insert queue
- (NSSet *)insertQueue{
    return [self getObjectFromQueue:kParseQueueInsert];
}

- (void)appendInsertQueue:(EWServerObject *)mo{
    [self appendObject:mo toQueue:kParseQueueInsert];
}

- (void)removeObjectFromInsertQueue:(EWServerObject *)mo{
    [self removeObject:mo fromQueue:kParseQueueInsert];
}

//uploading queue
- (NSSet *)workingQueue{
    return [self getObjectFromQueue:kParseQueueWorking];
}

- (void)appendObjectToWorkingQueue:(EWServerObject *)mo{
    [self appendObject:mo toQueue:kParseQueueWorking];
}

- (void)removeObjectFromWorkingQueue:(EWServerObject *)mo{
    [self removeObject:mo fromQueue:kParseQueueWorking];
}

//queue functions
- (NSSet *)getObjectFromQueue:(NSString *)queue{
    EWAssertMainThread
    NSArray *array = [[NSUserDefaults standardUserDefaults] valueForKey:queue];
    NSMutableArray *validMOs = [array mutableCopy];
    NSMutableSet *set = [NSMutableSet new];
    for (NSString *url in array) {
		NSURL *URI = [NSURL URLWithString:url];
        NSManagedObjectID *ID = [self.context.persistentStoreCoordinator managedObjectIDForURIRepresentation:URI];
        if (!ID) {
            DDLogError(@"@@@ ManagedObjectID not found: %@", url);
            //remove from queue
            [validMOs removeObject:url];
            [[NSUserDefaults standardUserDefaults] setObject:[validMOs copy] forKey:queue];
            continue;
        }
        NSError *error;
        EWServerObject *MO = (EWServerObject *)[self.context existingObjectWithID:ID error:&error];
        if (MO) {
            [set addObject:MO];
        }else{
            DDLogError(@"*** Serious error: trying to fetch MO from main context failed. ObjectID:%@ \nError:%@", ID, error.description);
            //remove from the queue
			[validMOs removeObject:url];
			[[NSUserDefaults standardUserDefaults] setObject:[validMOs copy] forKey:queue];
        }
    }
    return [set copy];
}

- (void)appendObject:(EWServerObject *)mo toQueue:(NSString *)queue{
    
    NSArray *array = [[NSUserDefaults standardUserDefaults] valueForKey:queue];
    NSMutableSet *set = [[NSMutableSet setWithArray:array] mutableCopy]?:[NSMutableSet new];
    NSManagedObjectID *objectID = mo.objectID;
    if ([objectID isTemporaryID]) {
        [mo.managedObjectContext obtainPermanentIDsForObjects:@[mo] error:NULL];
        objectID = mo.objectID;
    }
    NSString *URI = objectID.URIRepresentation.absoluteString;
    if (![set containsObject:URI]) {
        [set addObject:URI];
        [[NSUserDefaults standardUserDefaults] setObject:set.allObjects forKey:queue];
        if ([queue isEqualToString:kParseQueueInsert]) {
            DDLogDebug(@"+++> MO %@(%@) added to INSERT queue", mo.entity.name, mo.objectID);
        }else if([queue isEqualToString:kParseQueueUpdate]){
            DDLogDebug(@"===> MO %@(%@) added to UPDATED queue with changes: %@", mo.entity.name, mo.serverID, mo.changedKeys);
        }
        
    }
    
}

- (void)removeObject:(EWServerObject *)mo fromQueue:(NSString *)queue{
    NSMutableArray *array = [[[NSUserDefaults standardUserDefaults] valueForKey:queue] mutableCopy];
    NSManagedObjectID *objectID = mo.objectID;
    NSString *str = objectID.URIRepresentation.absoluteString;
    if ([array containsObject:str]) {
        [array removeObject:str];
        [[NSUserDefaults standardUserDefaults] setValue:[array copy] forKey:queue];
    }
}

- (void)clearQueue:(NSString *)queue{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:queue];
}

- (BOOL)contains:(EWServerObject *)mo inQueue:(NSString *)queue{
    NSMutableArray *array = [[[NSUserDefaults standardUserDefaults] valueForKey:queue] mutableCopy];
    NSString *str = mo.objectID.URIRepresentation.absoluteString;
    BOOL contain = [array containsObject:str];
    return contain;
}

//DeletedQueue underlying is a dictionary of objectId:className
- (NSSet *)deleteQueue{
    NSDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy];
    NSParameterAssert(!dic || [dic isKindOfClass:[NSDictionary class]]);
    NSMutableSet *set = [NSMutableSet new];
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *ID, NSString *className, BOOL *stop) {
        [set addObject:[PFObject objectWithoutDataWithClassName:className objectId:ID]];
    }];
    return [set copy];
}

- (void)appendObjectToDeleteQueue:(PFObject *)object{
    if (!object) return;
    NSMutableDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy]?:[NSMutableDictionary new];;
    [dic setObject:object.parseClassName forKey:object.objectId];
    [[NSUserDefaults standardUserDefaults] setObject:[dic copy] forKey:kParseQueueDelete];
}

- (void)removeObjectFromDeleteQueue:(PFObject *)object{
    if (!object) return;
    NSMutableDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy];
    [dic removeObjectForKey:object.objectId];
    [[NSUserDefaults standardUserDefaults] setObject:[dic copy] forKey:kParseQueueDelete];
}

//changed records
- (NSMutableDictionary *)changedRecords{
    if (_changedRecords) {
        return _changedRecords;
    }
	return [[[NSUserDefaults standardUserDefaults] valueForKey:kChangedRecords] mutableCopy] ?: [NSMutableDictionary new];
}

- (void)setChangedRecords:(NSMutableDictionary *)changedRecords{
    _changedRecords = changedRecords;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[NSUserDefaults standardUserDefaults] setValue:changedRecords.copy forKey:kChangedRecords];
    });
}

#pragma mark - Core Data
+ (NSManagedObject *)findObjectWithClass:(NSString *)className withID:(NSString *)serverID error:(NSError *__autoreleasing *)error{
	EWAssertMainThread
    
    NSManagedObject * MO = [self findObjectWithClass:className withID:serverID inContext:mainContext error:error];
    return MO;
}

+ (NSManagedObject *)findObjectWithClass:(NSString *)className withID:(NSString *)objectID inContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error{
    if (objectID == nil) {
        DDLogError(@"%s !!! Passed in nil to get current MO", __func__);
        return nil;
    }
    EWServerObject * MO = [NSClassFromString(className) MR_findFirstByAttribute:kParseObjectID withValue:objectID inContext:context];
    if (!MO) {
        PFObject *PO = [[EWSync sharedInstance] getParseObjectWithClass:className.serverClass ID:objectID error:error];
        MO = [PO managedObjectInContext:context];
        [MO refresh];
        if (!MO) {
            DDLogError(@"Failed getting exsiting MO(%@): %@", className, (*error).description);
        }
    }
    return MO;
}

+ (void)save{
	EWAssertMainThread
	if (mainContext.hasChanges) {
		[mainContext MR_saveToPersistentStoreAndWait];
	}
}

+ (void)saveWithCompletion:(EWSavingCallback)block{
    [[EWSync sharedInstance].saveCallbacks addObject:block];
    [mainContext MR_saveToPersistentStoreAndWait];
    [[EWSync sharedInstance] uploadToServer];
}

+ (void)saveAllToLocal:(NSArray *)MOs{
	if (MOs.count == 0) {
		return;
	}
	
	EWServerObject *anyMO = MOs[0];
    [anyMO.managedObjectContext obtainPermanentIDsForObjects:MOs error:NULL];
	
	//mark MO as save to local
	for (EWServerObject *mo in MOs) {
		[[EWSync sharedInstance].saveToLocalItems addObject:mo.objectID];
	}
	
	//remove from queue
	for (EWServerObject *mo in MOs) {
		//remove from the update queue
		[[EWSync sharedInstance] removeObjectFromInsertQueue:mo];
		[[EWSync sharedInstance] removeObjectFromUpdateQueue:mo];
	}
}


+ (BOOL)validateSO:(EWServerObject *)SO{
    //validate MO, only used when uploading MO to PO
    BOOL good = [EWSync validateSO:SO andTryToFix:NO];
    
    return good;
}

+ (BOOL)validateSO:(EWServerObject *)SO andTryToFix:(BOOL)tryFix{
    if (!SO) {
        return NO;
    }
    //validate MO, only used when uploading MO to PO
    BOOL good = YES;
    
    if (![SO valueForKey:kUpdatedDateKey] && SO.serverID) {
        DDLogWarn(@"The %@(%@) you are trying to validate haven't been downloaded fully. Skip validating.", SO.entity.name, SO.serverID);
        return NO;
    }
	
	good = [SO validate];
	if (!good) {
		if (!tryFix) {
			return NO;
		}
        //TODO: use more granular level fix, or use better way to fix
		[SO refresh];
		good = [SO validate];
	}
	
    if (!good) {
        DDLogError(@"*** %@(%@) failed in validation after trying to fix", SO.entity.name, SO.serverID);
    }
    
    return good;
    
}


+ (BOOL)checkAccess:(EWServerObject *)SO{
    if (!SO.serverID) {
        return YES;
    }
    
    //first see if cached PO exist
    PFObject *po = [[EWSync sharedInstance] getCachedParseObjectForID:SO.serverID];
    if (po.ACL != nil) {
        BOOL write = [po.ACL getWriteAccessForUser:[PFUser currentUser]] || [po.ACL getPublicWriteAccess];
        return write;
    }
    
    //if no ACL, use MO to determine
//    __block EWPerson *p;
//    if ([SO.entity.name isEqualToString:kSyncUserClass]) {
//        p = (EWPerson *)SO;
//    }else{
//        [SO.entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
//            if ([obj.destinationEntity.name isEqualToString:kSyncUserClass]) {
//                if (!obj.isToMany) {
//                    p = [SO valueForKey:key];
//                    *stop = YES;
//                }
//            }
//        }];
//    }
    EWPerson *p = (EWPerson *)SO.ownerObject;
    if (p.isMe){
        return YES;
    }
    return NO;
}


#pragma mark - Parse helper methods
+ (NSArray *)findServerObjectWithQuery:(PFQuery *)query error:(NSError **)error{
    //EWAssertMainThread
	NSArray *result = [query findObjects:error];
	for (PFObject *PO in result) {
		[[EWSync sharedInstance] setCachedParseObject:PO];
	}
	return result;
}

+ (void)findServerObjectInBackgroundWithQuery:(PFQuery *)query completion:(PFArrayResultBlock)block{//cache query
    EWAssertMainThread
    @try {
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            
            for (PFObject *PO in objects) {
                [[EWSync sharedInstance] setCachedParseObject:PO];
                [PO managedObjectInContext:mainContext];
            }
            if (block) {
                block(objects, error);
            }
        }];
    }
    @catch (NSException *exception) {
        if (block) {
            NSError *error = [NSError errorWithDomain:@"com.wokealarm.woke" code:102 userInfo:@{@"localizedDescription": @"Error code indicating you tried to query with a datatype that doesn't support it, like exact matching an array or object."}];
            block(nil, error);
        }
    }
	
}

- (PFObject *)getCachedParseObjectForID:(NSString *)objectId{
    return [self.serverObjectCache objectForKey:objectId];
}

- (void)setCachedParseObject:(PFObject *)PO {
    if (PO.isDataAvailable) {
        [self.serverObjectCache setObject:PO forKey:PO.objectId];
    }else{
        DDLogError(@"%s The PO passed in doesn't have data, please check!(%@)",__FUNCTION__, PO);
    }
    
}

- (PFObject *)getParseObjectWithClass:(NSString *)class ID:(NSString *)ID error:(NSError **)error{
    if (!ID) {
        DDLogError(@"%s Passed in empty ID, upload first!", __func__);
        return nil;
    }
    
    //try to find PO in the pool first
    PFObject *object = [self getCachedParseObjectForID:ID];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:class inManagedObjectContext:mainContext];
    
    //if not found, then download
    if (!object || !object.isDataAvailable) {
        //fetch from server if not found
        //or if PO doesn't have data avaiable
        //or if PO is older than MO
        PFQuery *q = [PFQuery queryWithClassName:class.serverClass];
        [q whereKey:kParseObjectID equalTo:ID];
        //add other uni-direction relationship as well (to masximize data per call)
        [entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
            if (obj.isToMany && !obj.inverseRelationship) {
                [q includeKey:key];
            }
        }];
        
        //find on server
        object = [[EWSync findServerObjectWithQuery:q error:error] firstObject];
        
        if (!object) {
            DDLogError(@"Cannot find PO: %@(%@)", class, ID);
            *error = [NSError errorWithDomain:@"com.wokealarm.woke" code:kPFErrorObjectNotFound userInfo:@{@"Class":class, @"objectId":ID}];
        }
    }
    return object;

}


#pragma mark - Tools
- (NSString *)description{
    //print current states and queues
    NSMutableString *string = [NSMutableString stringWithFormat:@"EWSync object with current reachability: %d", [EWSync isReachable]];
    [string appendFormat:@"\nCurrent updating item: %@", self.updatingClassAndValues];
    [string appendFormat:@"\nCurrent inserting item: %@", [self.insertQueue valueForKey:kParseObjectID]];
    [string appendFormat:@"\nCurrent deleting item: %@", [self.deleteQueue valueForKey:kParseObjectID]];
    return string;
}


- (NSDictionary *)updatingClassAndValues{
    NSMutableDictionary *info = self.changedRecords.mutableCopy;
    [self.changedRecords enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        PFObject *PO = [self getCachedParseObjectForID:key];
        if (PO) {
            [info removeObjectForKey:key];
            [info setObject:obj forKey:[NSString stringWithFormat:@"%@(%@)", PO.parseClassName, key]];
        }
    }];
    return info.copy;
}
@end


@implementation NSString (EWSync)

- (NSString *)serverType{
    NSDictionary *typeDic = kServerTransformTypes;
	NSString *serverType = typeDic[self];
    return serverType;
}

- (NSString *)serverClass{
	NSDictionary *typeDic = kServerTransformClasses;
	NSString *serverClass = typeDic[self]?:self;
	return serverClass;
}

- (BOOL)skipUpload{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", attributeUploadSkipped];
    BOOL result = [predicate evaluateWithObject:self];
    return result;
}

@end

